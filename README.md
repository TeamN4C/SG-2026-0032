# SG-2026-0032 — CVE-2026-43786 ManagedClient exploit validation

This `exploit` branch contains the compatibility harness used to validate the
public ManagedClient privilege-escalation chain on a MacBook Air (Mac17,5),
macOS Tahoe 26.6.2 (25G83), arm64. The process started as uid 501 without a
private entitlement. Its ManagedClient bind reply returned `err=0`, the
synthetic LDAP account resolved with primary gid 80 (`admin`), and `sudo id`
returned `uid=0(root)`. The unbind reply returned `err=0`; subsequent checks
found no synthetic user, LDAP search-path entry, TCP/389 listener, or test
launchd job.

## Origin and changes

The code derives from [Malwation's public CVE-2026-43786 C file][upstream] at
commit `8de21f0d051d76ce4a1e4a906578ba502a7310de` (upstream file SHA-256:
`a7544a5fde46f0502bf1329e8713ffe511a65bc418242d6c4fbfffcdc0bfde39`).
This branch keeps the ManagedClient MIG request, synthetic administrator
account, `su`/`sudo` verification, and unbind flow. It adds loopback-only LDAP,
per-user launchd socket activation for TCP/389, LDAP entries required by the
tested AppleODClient, and diagnostic output. The LDAP mapping is generated
locally from macOS's `AppleOpenLDAP.plist`; Apple's mapping file is not included
in this branch.

The as-published upstream source did not complete on the tested machine:
an unprivileged process could not bind TCP/389 directly, and the original LDAP
DIT did not satisfy the current AppleODClient discovery queries. The results
above are from this compatibility harness, not an unchanged upstream run.

## Files

| File | Purpose |
| --- | --- |
| `CVE-2026-43786.c` | Compatibility-harness source |
| `CVE-2026-43786-arm64` | Validated arm64 build for 25G83 |
| `run.sh` | Exact-build preflight, temporary launchd run, and cleanup checks |
| `launchd.plist.in` | Template for a loopback TCP/389 user agent |
| `SHA256SUMS` | Hash receipt for the distributed files |

## Run on the validated build

From this directory on macOS Tahoe 26.6.2 (25G83), arm64, as a normal user:

```sh
sh ./run.sh
```

The script checks the OS build, architecture, binary hash, existing TCP/389
listener, synthetic user, and Open Directory search path before starting. It
creates a temporary LDAP mapping and launchd agent, prints the bind/root/cleanup
markers, then removes the agent, listener, mapping, and temporary logs. A
failure path also attempts ManagedClient unbind. The hard-coded account and
password in the C file are synthetic test data.

To rebuild the arm64 binary from the source on this macOS version:

```sh
xcrun clang -O2 -Wall -Wextra -DUSE_LAUNCHD_SOCKET \
  -o CVE-2026-43786-arm64 CVE-2026-43786.c \
  -framework CoreFoundation -lutil
```

The build used for the reported reproduction has source SHA-256
`66d1859e9dd6e5e47bae736e98eb2eeaa80b7228d32390639f6d7339ba506ec8`
and binary SHA-256
`a37cae93e6907f8eef1a637b865082b7099d04fd33bf3b9f0af59d1cdf1cff82`.
`run.sh` accepts only that validated binary; a locally rebuilt binary may have
a different hash and must be reviewed before use.

The patched Tahoe 26.7 binary was compared statically, but this harness was
not run on 26.7. The validation above does not demonstrate behavior on other
macOS releases or architectures.

[upstream]: https://github.com/Malwation/CVE-2026-43786/blob/8de21f0d051d76ce4a1e4a906578ba502a7310de/CVE-2026-43786.c
