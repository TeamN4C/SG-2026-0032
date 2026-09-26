# SG-2026-0032 — CVE-2026-43786

This repository preserves the public [Malwation proof of concept][upstream] as a
GitHub fork and separates the N4C-tested compatibility payload into its own
branch.

| Branch | Contents |
| --- | --- |
| [`main`](https://github.com/TeamN4C/SG-2026-0032/tree/main) | Unmodified upstream source and demonstration video from the fork |
| [`poc`](https://github.com/TeamN4C/SG-2026-0032/tree/poc) | Upstream PoC snapshot for the report's source walkthrough |
| [`exploit`](https://github.com/TeamN4C/SG-2026-0032/tree/exploit) | N4C compatibility harness, validated arm64 binary, launchd runner, README, and SHA-256 receipt |

The as-published upstream C file did not complete unchanged in the tested
macOS Tahoe 26.6.2 (25G83) environment because an unprivileged process could
not bind TCP/389 directly and the original LDAP entries did not satisfy the
tested AppleODClient discovery queries. The `exploit` branch documents the
changes, the observed `uid=0(root)` result, and the cleanup checks. Its README
also states the tested OS/architecture boundary.

[upstream]: https://github.com/Malwation/CVE-2026-43786/blob/8de21f0d051d76ce4a1e4a906578ba502a7310de/CVE-2026-43786.c
