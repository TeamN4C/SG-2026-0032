# SG-2026-0032 — PoC source

This branch provides the N4C compatibility revision of the public
CVE-2026-43786 C proof of concept. The `CVE-2026-43786.c` here is byte-for-byte
the same source as the [validated `exploit` branch][exploit-source] at revision
`91546a0fdaa07e7d99d2d0f32d219acdd413df15`.

The revision keeps the ManagedClient MIG bind/unbind requests, LDAP account and
admin-group responses, and `su`/`sudo` verification. It adds loopback-only LDAP,
per-user launchd socket activation for TCP/389, and the directory entries
required by the tested AppleODClient. It also uses a configurable mapping XML
path instead of a local absolute path.

The source SHA-256 is
`66d1859e9dd6e5e47bae736e98eb2eeaa80b7228d32390639f6d7339ba506ec8`.
The original [Malwation source][upstream-source] at commit
`8de21f0d051d76ce4a1e4a906578ba502a7310de` has SHA-256
`a7544a5fde46f0502bf1329e8713ffe511a65bc418242d6c4fbfffcdc0bfde39`.
`poc.mov` is the upstream video, not a recording of the N4C validation.

The revised source was validated on macOS Tahoe 26.6.2 (25G83), arm64, with a
uid 501 process without a private entitlement. ManagedClient bind returned
`err=0`; the LDAP user resolved with primary gid 80 (`admin`); and `sudo id`
returned `uid=0(root)`. The as-published upstream source did not complete
unchanged on this machine because of TCP/389 and LDAP discovery compatibility
issues. The [exploit branch][exploit] contains the exact validated binary,
launchd runner, and cleanup checks. No dynamic run on patched 26.7 is claimed.

[exploit-source]: https://github.com/TeamN4C/SG-2026-0032/blob/91546a0fdaa07e7d99d2d0f32d219acdd413df15/CVE-2026-43786.c
[upstream-source]: https://github.com/Malwation/CVE-2026-43786/blob/8de21f0d051d76ce4a1e4a906578ba502a7310de/CVE-2026-43786.c
[exploit]: https://github.com/TeamN4C/SG-2026-0032/tree/exploit
