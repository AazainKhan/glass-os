# Third-party software in Glass Pro

Glass Pro ships upstream binaries unmodified and never re-signs them, so in-app updates keep working and the
licences below are met as written. Versions, download URLs, sha256 and signer certificate digests are pinned in
`config/bundled-apps.tsv`; `tools/fetch_apps.sh` refuses anything that does not match.
Licence readings come from `research/replacements.md`; they are a summary, not legal advice.

| Component | Version | Where it goes | Licence | Source |
|---|---|---|---|---|
| Droid-ify (`com.looker.droidify`) | 0.7.8, `app-release.apk` (the only release flavour) | `/system/priv-app/Droidify` + privapp allowlist | GPL-3.0-or-later | https://github.com/Droid-ify/client (tag v0.7.8) |
| TV Bro (`com.phlox.tvwebbrowser`) | 2.1.6, `generic-geckoExcluded` build (uses the system WebView) | `/system/app/TVBro` | Custom BSD-like licence: https://github.com/truefedex/tv-bro/blob/master/LICENSE.md | https://github.com/truefedex/tv-bro (tag v2.1.6) |
| `glass-keymap` | built from the Glass TV Launcher repository | module root, run by the remote-keys service | Apache-2.0 | `tools/keymap/glass-keymap.c` in the Glass TV Launcher repository |
| Glass TV Launcher | the APK passed to `tools/glasspro/build.sh` | `/system/priv-app/GlassLauncher` | Apache-2.0 | Glass TV Launcher repository |
| avbtool.py (build tool, not shipped) | AOSP `external/avb`, commit pinned in `tools/fetch-tools.sh` | not in any output | Apache-2.0 | https://android.googlesource.com/platform/external/avb |

## Droid-ify (GPL-3.0-or-later)

The APK is the unmodified upstream release, so the upstream repository at the tagged commit is the complete
corresponding source and the written offer: https://github.com/Droid-ify/client/tree/v0.7.8. The licence text is at
https://www.gnu.org/licenses/gpl-3.0.txt and in the upstream repository. The module installs it as a privileged app
so it can install and remove F-Droid apps without a prompt; the allowlist lists exactly the permissions it requests
that this Android 11 image declares, plus `INSTALL_PACKAGES` and `DELETE_PACKAGES`.

## TV Bro (custom licence)

The upstream licence allows redistribution of the unmodified binary when it is identical to an official release.
The bundled file is byte-identical to the release asset `tvbro-2.1.6-generic-geckoExcluded.apk`
(sha256 in `config/bundled-apps.tsv`), carries the upstream signature, and is not renamed or altered. Do not
repackage, re-sign or patch it: that would void the licence's "identical" condition and break updates.
Copyright and disclaimer: see the upstream `LICENSE.md` linked above.

## Not bundled

Aurora Store (Google Play anonymous accounts risk breakage; install it from Droid-ify if wanted), Obtainium
(install from inside Droid-ify), Magisk (required, installed by the user), Amazon software (none; the module only
hides Amazon packages, it contains no Amazon file).
