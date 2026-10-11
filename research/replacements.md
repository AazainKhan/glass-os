# Open-source replacements for Fire TV Stick 4K 2nd gen (research only, no device touched)

Research date 2026-10-10. Tags: [S] = read in primary source (repo file, API, store page); [W] = search snippet only; [I] = my inference, not sourced.
"GitHub SPDX" = what GitHub's licence detector reports, which is only a hint and can say GPL-3.0 for GPL-3.0-or-later.

## 1. App stores

| | Aurora Store | F-Droid client | Droid-ify | Obtainium |
|---|---|---|---|---|
| Licence | GPL-3.0-or-later [S] https://gitlab.com/AuroraOSS/AuroraStore (README also says "GPLv3" https://gitlab.com/AuroraOSS/AuroraStore/-/raw/master/README.md) | GPL-3.0-or-later [S] https://f-droid.org/en/packages/org.fdroid.fdroid/ | GPL-3.0-or-later [S] https://raw.githubusercontent.com/Droid-ify/client/main/README.md (GitHub SPDX: GPL-3.0, https://api.github.com/repos/Droid-ify/client) | GitHub SPDX GPL-3.0 only, exact -only/-or-later not confirmed [S] https://api.github.com/repos/ImranR98/Obtainium |
| Latest | 4.8.4, 2026-07-27 [S] https://gitlab.com/api/v4/projects/AuroraOSS%2FAuroraStore/releases | 2.0.1 beta, 2026-09-29, minSdk 24 [S] https://f-droid.org/en/packages/org.fdroid.fdroid/ (the GitHub mirror's "latest" is stale: 1.18.0, Jan 2024, https://api.github.com/repos/f-droid/fdroidclient/releases/latest) | v0.7.8, 2026-09-12 [S] https://api.github.com/repos/Droid-ify/client/releases/latest | v1.6.17, 2026-09-13 [S] https://api.github.com/repos/ImranR98/Obtainium/releases/latest |
| Maintained | Yes, but release cadence ~2-3 months (4.8.1 Feb, 4.8.3 May, 4.8.4 Jul) [S] same releases API | Yes (beta 2.x line) | Yes, last push 2026-09-12 [S]; 196 open issues | Yes, last push 2026-09-13 [S] |
| Leanback launcher entry | Yes, `LEANBACK_LAUNCHER` on ComposeActivity; leanback + touchscreen `required=false` [S] https://gitlab.com/AuroraOSS/AuroraStore/-/raw/master/app/src/main/AndroidManifest.xml | Yes, same flags [S] https://gitlab.com/fdroid/fdroidclient/-/raw/master/app/src/main/AndroidManifest.xml | Yes, same flags [S] https://raw.githubusercontent.com/Droid-ify/client/main/app/src/main/AndroidManifest.xml | Yes, same flags [S] https://raw.githubusercontent.com/ImranR98/Obtainium/main/android/app/src/main/AndroidManifest.xml |
| Real D-pad quality | Unverified. Open issue "Implement better support for large screen devices" (2024-02, updated 2026-05) says TVs can launch it without proper leanback support; no D-pad/Fire TV detail [S] https://gitlab.com/AuroraOSS/AuroraStore/-/work_items/1053 | Unverified. F-Droid forum has a long "TV only" UI/D-pad thread, i.e. TV usability is a known open topic [W] https://forum.f-droid.org/t/new-ui-ux-tv-only-discussion-tv-layout-keyboard-d-pad/2677 | Unverified; the manifest declares TV intent, README says nothing on TV | Unverified; Flutter UI, URL entry by remote is awkward [I] |
| Silent install as priv-app | Installer choices: Session (default), Native, Root, Service (Aurora's own privileged extension, v9+), AppManager, Shizuku, microG [S] https://gitlab.com/AuroraOSS/AuroraStore/-/raw/master/app/src/main/java/com/aurora/store/data/installer/AppInstaller.kt | Needs separate Privileged Extension `org.fdroid.fdroid.privileged` 0.2.14 (2026-10-06, Apache-2.0, perms INSTALL_PACKAGES + DELETE_PACKAGES, "requires root" as system app) [S] https://f-droid.org/en/packages/org.fdroid.fdroid.privileged/. Compatibility with client 2.0.x not verified | README: Session, Root, Shizuku installers; no privileged-extension mode [S] https://raw.githubusercontent.com/Droid-ify/client/main/README.md | Declares UPDATE_PACKAGES_WITHOUT_USER_ACTION; the bg-update job installs only apps passing `canInstallSilentlyInBackground()`, else just notifies [S] https://raw.githubusercontent.com/ImranR98/Obtainium/main/lib/providers/apps_provider.dart. Shizuku permission appears in F-Droid listing [W] https://f-droid.org/ko/packages/dev.imranr.obtainium.fdroid/; the install logic file was not read |
| Unattended updates | Yes: optional battery-opt exemption; declares UPDATE_PACKAGES_WITHOUT_USER_ACTION [S] README | Yes, via privileged ext. (background update service) [I] | Yes: "automatic app updates in the background" [S] README | Yes, background updates with Wi-Fi/charging constraints [S] apps_provider.dart |

Platform note: UPDATE_PACKAGES_WITHOUT_USER_ACTION / update-ownership are Android 12+ APIs [I]; this stick is Android 11, so for unattended installs rely on a privileged `INSTALL_PACKAGES` holder (priv-app), root or Shizuku rather than those permissions.

Other stores:
- Neo Store: not researched (no fresh source gathered). Skip unless asked.
- APKUpdater (rumboalla): GPL-3.0, last push 2026-05-28 [S] https://api.github.com/repos/rumboalla/apkupdater. It is the only one found that is explicitly TV-targeted in my memory, but TV claims were not verified [I].
- No TV-oriented FOSS store with fresh evidence was found.

Aurora risk: uses Google Play anonymous accounts. Dispenser (anonymous login provider) was taken down once because Google aggressively blocks the accounts; later said fixed [W] https://discuss.grapheneos.org/d/5199-psa-aurora-store-will-be-down-for-a-while. Google deleted accounts used only with Aurora [W] https://discuss.techlore.tech/t/aurora-store-anonymous-logins-are-removed-indefinitely/3817. A 2026-09 aggregator item reports "Server busy" failures with anonymous accounts [W, date uncertain]. Anonymous login lacks library/purchases/betas [S] README. Treat as ToS-grey and prone to breakage.

### Recommendation (store)
- Primary: Droid-ify. GPL-3.0+, Leanback launcher entry, browse-style UI (no typing URLs with a remote), background auto-update, Root installer works with Magisk. Supports custom repos (add IzzyOnDroid, SmartTube etc. if they publish repos) [S README].
- Secondary (optional): Obtainium, preloaded with an exported app-list JSON for GitHub-only TV apps (e.g. launchers, YouTube clients). Typing GitHub URLs by remote is painful, so pre-seed rather than expect interactive use [I].
- Do not bundle Aurora; install by hand only if a Play-only app is needed. Its `preload` APK variant exists (AuroraStore-preload-4.8.4.apk) [S release assets] but its purpose/behaviour was not read.
- Caveat: no source confirms any of these four is D-pad-comfortable. Test each on the stick before committing.

## 2. Browser (replace Silk)

| Browser | Licence | Maintenance | TV fit | Engine |
|---|---|---|---|---|
| TV Bro (`truefedex/tv-bro`) | Custom BSD-like licence (GitHub: NOASSERTION), see section 3 [S] https://raw.githubusercontent.com/truefedex/tv-bro/master/LICENSE.md | v2.1.6 2026-06-01; last push 2026-10-10 [S] https://api.github.com/repos/truefedex/tv-bro/releases/latest | Built for TV; README lists "working with TV remote", shortcuts; Leanback entry in manifest [S] https://raw.githubusercontent.com/truefedex/tv-bro/master/README.md, manifest https://raw.githubusercontent.com/truefedex/tv-bro/master/app/src/main/AndroidManifest.xml. Cursor/D-pad specifics not on the README page | Two builds: `generic-geckoExcluded` (system WebView) and `geckoIncluded` per-ABI (bundled GeckoView) [S] release assets |
| Fulguris | MPL-2.0 per IzzyOnDroid listing; GitHub says NOASSERTION [W] https://apt.izzysoft.de/fdroid/index/apk/net.slions.fulguris.full.fdroid?repo=main | Active, last push 2026-10-07 [S] https://api.github.com/repos/Slion/Fulguris | Phone/tablet/Chromebook oriented; no TV claim found | System WebView |
| Mull | Fork of Fennec | Archived 2024-12-23 [W] F-Droid forum via search | Phone | GeckoView; do not use |
| Fennec F-Droid / Firefox forks | MPL-2.0 [I] | Active [W] | No TV/D-pad evidence found | GeckoView, heavy for 2 GB [I] |
| Firefox for Fire TV (`org.mozilla.tv.firefox`) | MPL-2.0 [I] | Old listings 2017-2021 only [W] https://www.apkmirror.com/?p=2517513 | Made for Fire TV remote | Gecko/WebView; likely unmaintained |
| Kiwi | open | Discontinued Jan 2025, repo archived [W] https://www.alternativeto.net/news/2025/1/kiwi-browser-discontinued-explore-alternatives-for-extension-support-and-security/ | n/a | n/a |
| Quetta | Not open source (2024 report) [W] https://www.punto-informatico.it/quetta-nuovo-browser-android-senza-pubblicita/ | n/a | n/a | Closed, exclude |
| BrowseHere | Closed (per task brief) | | | Exclude |

WebView on this stick: Fire TV uses "Amazon WebView", a custom hardware-optimised Chromium build, usable through the standard WebView API [S] https://developer.amazon.com/docs/fire-tv/hybrid-apps-overview.html (page dated 2020). Chromium version for Fire OS 8 and its update channel were NOT found in any source. Check on device: `dumpsys webviewupdate` / package version of the WebView provider. This decides whether modern sites work in TV Bro's WebView build.

Memory: bundling GeckoView adds per-ABI APK weight and Gecko RAM use; no measurements found [I]. On a 2 GB device prefer the WebView build.

### Recommendation (browser)
TV Bro, `tvbro-2.1.6-generic-geckoExcluded.apk` (system WebView, small, TV-first). Fallback if the stock WebView proves too old: the `geckoIncluded-arm64-v8a` build (verify ABI of the stick first; MT8696 may run a 32-bit userland, so `armeabi-v7a` is plausible [I]).

## 3. Shipping, licences, signing, permissions

Delivery options, in order of simplicity [I]:
1. Magisk module overlaying `/system/priv-app/<Name>/<Name>.apk` (+ `/system/etc/permissions/privapp-permissions-<name>.xml`). Existing `glass-system` module already uses this pattern per project CLAUDE.md.
2. Rebuilt image: same files in the image; needs a repack and is far heavier.
3. First-run download: no system privilege, so no silent installs. Not recommended for the store.

Priv-app allowlist rules [S] https://source.android.com/docs/core/permissions/perms-allowlist:
- XML goes in `/etc/permissions/` of the same partition as the priv-app; one `<privapp-permissions package="...">` block per app with `<permission name="..."/>` entries.
- Android 9+: a signature|privileged permission requested but not allowlisted can stop boot when enforcement is on ("the device won't boot"). Use `ro.control_privapp_permissions=log` while testing. Only request what you allowlist, and test the module with a safe-mode/disable path (Magisk module removal) available.

| App | Install path | Licence / redistribution | Signing | privapp-permissions XML |
|---|---|---|---|---|
| Droid-ify | `/system/priv-app/Droid-ify/` | GPL-3.0-or-later: ship GPL text and notices, offer source (link to the tagged commit; shipping an unmodified upstream APK means the upstream repo suffices as the offer) [S licence per README] | Use the upstream GitHub release APK as-is so in-app updates match. Releases carry .idsig/.sha256 files [S assets]. Two flavours exist (`app-release` and `app-fdroid-release`, different signers likely [I]); pick one and never mix | `INSTALL_PACKAGES`, `DELETE_PACKAGES` (to let Session install be silent; the app's own manifest requests only REQUEST_INSTALL/DELETE and UPDATE_PACKAGES_WITHOUT_USER_ACTION [S]). Add `UPDATE_PACKAGES_WITHOUT_USER_ACTION` only if the framework defines it (API 31+; harmless to omit on API 30 [I]). Whether Droid-ify actually uses these when privileged: untested, may need Root installer instead [I] |
| Obtainium (optional) | `/system/priv-app/Obtainium/` | GPL (v3 per GitHub); same obligations | Single signer, hash published on the wiki (`dev.imranr.obtainium`) [S] https://wiki.obtainium.imranr.dev/. Note F-Droid build is `dev.imranr.obtainium.fdroid` with F-Droid's signature [W]; keep one source | Same pair: `INSTALL_PACKAGES`, `DELETE_PACKAGES` |
| TV Bro | `/system/app/TVBro/` (no privilege needed) | Custom licence: unmodified binary may be redistributed only if identical to an official release on its GitHub releases page; modified builds must rename, change icon and application ID, and add an About window crediting it; keep copyright and disclaimer [S] https://raw.githubusercontent.com/truefedex/tv-bro/master/LICENSE.md. Not legal advice | Keep the official APK untouched (any re-sign breaks both the licence's "identical" clause and updates) | None needed. Its manifest asks for camera, mic, location, REQUEST_INSTALL_PACKAGES, etc. as normal runtime perms [S] |
| Aurora (if ever) | `/system/priv-app/AuroraStore/` | GPL-3.0-or-later | Use the `-preload` or normal APK from GitLab releases consistently [S names only] | `INSTALL_PACKAGES`, `DELETE_PACKAGES`, `UPDATE_PACKAGES_WITHOUT_USER_ACTION`; or use Aurora's "Service" installer with its extension [S AppInstaller.kt] |
| F-Droid client + Privileged Ext. (alternative) | Client in `/system/app`, extension in `/system/priv-app/org.fdroid.fdroid.privileged/` | Client GPL-3.0+, extension Apache-2.0 [S] | Extension 0.2.14 checks the client's signature [I], so client and extension must come from the same F-Droid build | Extension needs `INSTALL_PACKAGES`, `DELETE_PACKAGES` [S] https://f-droid.org/en/packages/org.fdroid.fdroid.privileged/ |

General notes:
- GPL: an unmodified APK in a module zip needs the licence text and a written source offer or pointer (upstream tag URLs) in the module README [I, not legal advice].
- A system copy of an app updates in place via its own installer only if the update is signed with the same key as the system copy; once a user-installed update lands in `/data/app`, Magisk overlay re-install of an older system APK is ignored unless versionCode is higher [I].
- Remove Silk and the Amazon Appstore package-by-package only after the replacement launches via the Leanback category, so Glass shows an entry [I].

## Open questions to resolve on the device (main agent)
1. WebView provider and Chromium version (decides TV Bro build and whether any modern browser works).
2. 32-bit vs 64-bit userland (decides APK ABI).
3. D-pad usability of Droid-ify and TV Bro by actually driving them.
4. Whether session installs by a priv-app with INSTALL_PACKAGES are fully silent on Fire OS 8 (Amazon may modify PackageInstaller).
