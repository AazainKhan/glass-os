# Glass OS: tvOS system map

Date: 2026-10-11. Status: planning. Device: Fire TV Stick 4K 2nd Gen (karat, MT8696), Fire OS 8.1.8.2.

Goal: "tvOS as an OS on Fire TV". A Fire OS based ROM whose whole system experience (not only the launcher) behaves like a current Apple TV, built from behaviour and measured values only.

This is an internal planning document. It names tvOS classes and apps as **evidence** for what exists and how it is organised. Nothing from Apple ships: no code, header text, strings, assets or fonts, and no Apple product name is used as a Glass UI name (see section 6 for the names Glass uses today that need review).

Sources:
- tvOS 26.6 decompile index: Objective-C interface and protocol names for 1,834 dyld images and 61 apps, plus `animations.tsv` (7,713 Core Animation rows from 145 archives). Only names and animation parameters were read. No member declarations are quoted here.
- Fire OS 8.1.8.2 decompile index: 281 packages, 2,594 components, 2,058 intent actions, java class and member lists. Manifest facts (shared uid, HOME category) come from `packages.tsv`.
- Existing plan documents in this folder (`glass-os-spec.md`, `glass-os-plan.md`, `decisions-2026-10-10.md`) and the Glass install-mode study.

## 1. How the two systems are laid out

tvOS has a small number of system processes and each owns a clear surface. Fire OS spreads the same jobs across many Amazon packages plus stock SystemUI. The mapping is therefore not one to one.

| tvOS owner | What it is (evidence) | Fire OS counterpart |
|---|---|---|
| PineBoard (608 interfaces) | Home shell, app lifecycle, overlays, bulletins, critical alerts, dialogs, display, profiles, volume, Siri hand-off, attention/idle state machines. Class families `PBSystem*`, `PBUser*`, `PBApp*`, `PBOverlay*`, `PBBulletin*`, `PBCriticalAlert*`, `PBDialog*`, `PBAttention*`, `PBRestriction*`, `PBLoreto*` (profiles) | `com.amazon.tv.launcher` (HOME, 93 components), `com.amazon.firehomestarter`, plus SystemUI policy |
| TVSystemUIService (352) | HUD-style system UI: menu bar and the system menu (`TVSSMenu*`, `TVSSControlCenter*`), Now Playing (`TVSSNowPlaying*`, 18), Sleep Timer (`TVSSSleepTimer*`), headphones, game controllers, privacy indicators, HomeKit, FaceTime banners | `com.android.systemui` (uid `android.uid.systemui`), `com.amazon.tv.quicksettings.ui` |
| TVSystemMenuUI (39) | Control Center module/grid classes (`TVSMButtonModule`, `TVSMCollectionModule`, `TVSMButtonGridCollectionViewLayout`) | `com.amazon.tv.quicksettings.ui` (25 components) |
| TVSettings (301) + TVSettingsFoundation | Sidebar plus gallery settings (`TVSASidebar*`, `TVSAGallery*`, `TVSANavigationSplitViewController`) | `com.amazon.tv.settings.v2` (177 components, 59 activities) and `settings.core` (uid `android.uid.system`) |
| TVSetup (168) | First-run flow (`SATVActivation*`, `BuddyWifiAutoJoiner`, account steps, 24 animated illustrations) | `com.amazon.tv.oobe` (34 components, HOME category), `ffsprovisioneeclient`, `whisperjoin` |
| IdleScreen, TVScreenSaver, TVIdleServices (152), PosterBoard | Idle screen and Aerial service (`TVISAerialAsset`, `TVISAerialManifest`, `TVISAerialStore`) | `com.amazon.ftv.screensaver` (Dream service, 43 components) |
| TVAirPlay (26), TVNowPlayingService (21), AirPlaySenderUIApp | Receiver sessions, PIN, mirroring view, route list | `com.amazon.cast.sink` (uid system), `whisperlink`, `dialservice` |
| Siri (86) | Assistant UI cards and sheets | `com.amazon.vizzini` (87 components, 46 permissions) with `aria`, `imp` |
| TVRestrictionPINService, TVUserProfileService | PIN entry, profile suggestions | `com.amazon.tv.parentalcontrols` (49 components), `com.amazon.ftv.profilepicker` |
| GameCenterUI (426), GameController (296), TVGameCenterUIService | Social gaming layer, controller settings | none (controllers only under `settings.v2`) |

## 2. The map

Statuses: **already in Glass** (works in Glass today, per the install-mode study built from Glass master), **needs building** (Glass work, no Fire app removed), **replace a Fire app** (Glass takes over a Fire package's job and the package can be removed or disabled), **not feasible** (keep Fire's component; at most a skin).

"Glass equivalent" uses neutral names. "Keep" lists Fire packages that must stay running.

| # | tvOS surface | Glass OS equivalent | Status | Fire package(s): replaces / must keep | Evidence (tvOS; Fire) |
|---|---|---|---|---|---|
| 1 | Home / PineBoard | Glass Home: rows, dock, folders, top shelf, app switcher, launch and close transitions, wallpaper | already in Glass | Replaces `com.amazon.tv.launcher`, `firehomestarter` (disabled today). Keep `com.amazon.tv.settings.v2` (also HOME), `oobe` (HOME), `whisperlink.core.android` (HOME category, own uid). Alexa video search results are routed into launcher deep-link activities (see 4 and risk F1) | PineBoard (608 interfaces, `PBHomeUIManager`, `PBAppSwitcher*Layout`, `PBDismissControlCenterTransitionHint`); `tv.launcher` (93 components, `SearchResultsDeepLinkActivityDI`, `MainSettingsActivity`) |
| 2 | Control Center | Glass quick panel: customizable tiles, pages, edit mode, sleep, restart, clean up, VPN, add-on tiles | already in Glass | Replaces nothing yet. Over apps it needs the remote-keys keymap (Fire's Settings key is swallowed by `FireTVKeyPolicyManager`, scan code 249). Keep `quicksettings.ui` (its receivers also own picture menu and global keys) | `TVSystemMenuUI` (39: `TVSMButtonGridCollectionViewLayout`, `TVSMButtonModule`), `TVSSControlCenter*`, `TVSSMenuBar*`; `quicksettings.ui` (`GlobalKeyHandler`, `QSLaunchButtonPressReceiver`, `PictureMenuNavigationReceiver`) |
| 3 | Settings | Glass settings shell: sidebar plus gallery pages for Glass options; Fire sub-activities opened for network, display, CEC, accessibility, storage, factory reset | needs building | Keep `settings.v2` and `settings.core` (network, display modes, HDR, CEC, OTA, reset live there; three sections need a signature|privileged permission, so Glass opens them as root today). Glass shell sits in front, not instead | `TVSettings` (301: `TVSANavigationSplitViewController`, `TVSASidebarCell`, `TVSAGalleryViewController`); `settings.v2` (59 activities, e.g. `NetworkActivity`, `DisplayAndSoundsActivity`, `AccessibilityActivity`, `FactoryResetActivity`, `ControllersAndBluetoothActivity`) |
| 4 | TV app (watchlist, Up Next) | "Watch" row: Up Next across services from the Watch Next provider, apps' continue channels and add-on feeds, deep links into the app | needs building | Keep `com.android.providers.tv` and `com.amazon.providers.tv` (data), Prime Video (venezia, `tv.support`, `ottssocompanionapp`, `identity`). Alexa search result screens are in `tv.launcher`; verify they still open with the launcher disabled (F1) | `AppleTV` app (6 interfaces; logic in `WatchListKit`, `TVAppServices` 61: `IntentDonationServiceObjC`, `SportsFavoriteServiceObjC`); `providers.tv`, `TvRows` in Glass |
| 5 | Music / Now Playing | Now Playing screen and cover-flow browser for any MediaSession or media browser app, lyrics only if the app supplies them | needs building | Replaces the `bueller.music` stub launcher entry. Keep Alexa media players (`alexamediaplayer.runtime.ftv`, `externalmediaplayer`) | `TVMusic` (325: `TVMLagunaControlsShadowView`, `TVMLibrarySortMenu`, lyrics classes in `TVMusicUI`), `TVNowPlayingService` (21), `TVSSNowPlaying*` (18); `bueller.music` (2 components, stub) |
| 6 | Photos | Photo source and viewer for local, SMB/DLNA and cloud-album feeds, also the screensaver's photo source | replace a Fire app | Replaces `bueller.photos` (stub, 1 activity) and the Amazon Photos source in the screensaver (`PhotosMAPInformationProvider`). Keep `kso.blackbird` until triaged (web view host) | `TVPhotos` (136: `TVPCachingManager`, `TVPCollectionViewFlowLayout`, `TVPDeckImageView`), `TVPhotoSources`, `PhotosUI`; `bueller.photos`, `ftv.screensaver` |
| 7 | Search | Glass search: installed apps, Watch Next titles, app deep links, voice hand-off to Alexa | needs building | Keep Alexa (`vizzini`, `aria`, `alexadirectivebrokerservice`). Text search action `SHOW_TEXT_SEARCH` and result screens are in `tv.launcher`; Glass must register for them or forward | `TVSearch` app (1 interface; logic in `TVSearchServices` 10, `SearchUI`, `OmniSearch`); `tv.launcher` (`TextSearchDeepLinkActivityDI`, `DirectiveSearchResultsActivityDI`) |
| 8 | Screensaver / Aerials | Glass idle screen with its own landscape video loop, clock and location labels, burn-in care | already in Glass | Replaces `ftv.screensaver` (Dream service, `BIND_DREAM_SERVICE`). Glass sets itself as screensaver with WRITE_SECURE_SETTINGS or root; otherwise it starts the idle screen from Home after N minutes | `IdleScreen`, `TVScreenSaver`, `TVIdleServices` (152: `TVISAerialManifest`, `TVISAerialStore`, `TVISAerialOrderingService`); `ftv.screensaver` (`ScreensaverService`, `TakeoverChooserService`) |
| 9 | AirPlay | Wireless receive via the PhairPlay add-on, toggle in the quick panel | already in Glass | Keep `cast.sink` (uid system), `whisperlink.core.android`, `whisperplay.contracts`, `dialservice`: Fire's own mirroring and DIAL stay alongside | `TVAirPlay` (26: `TVAirPlayAPRKMirroringView`, `TVAirPlayPINViewController`, `TVAirPlaySessionManager`), `AirPlaySenderUIApp`; `cast.sink` (3 components) |
| 10 | Siri | Voice skin: listening orb and answer cards driven by Alexa's events | not feasible | Keep all of Alexa: `vizzini`, `aria` (removing it crashes every hold), `imp`, `identity`, `alexa*`. Glass can only change how the mic key is routed and what it draws around Alexa, not the engine | `Siri` (86: `SRBigButtonView`, `SRCompactResultPlatterViewController`, `SRCardStackNavigationTransitionController`), `SiriTVUI` (7); `vizzini` (exported `ListenReceiver`, `RequestProcessing*Receiver`) |
| 11 | Game Center / controllers | Controller toast, battery tile, low-battery warning, "resume game" on connect, pad navigates Glass. No social layer | needs building | Keep `settings.v2` controllers pages (`ControllersAndBluetoothActivity`, `CustomizableButtonsActivity`), `fireinputdevices`, `bluetoothkeymaplib`, Bluetooth stack. Game Center service itself has no counterpart and none is planned | `GameCenterUI` (426), `GameControllerUI`, `TVSSGameController*`, `PBCriticalRemoteBatteryAlertManager`; `fireinputdevices` (1 component) |
| 12 | Onboarding / setup | Glass first-run after Fire's registration: make Glass home, remote check, display and sound, store, accessibility toggle | needs building | Keep `oobe` (registration, Wi-Fi, account; HOME category), `ffsprovisioneeclient`, `whisperjoin`, `autopairservice`, `uxcontrollerservice`. Glass never replaces OOBE: it needs MAP registration to reach Prime and Alexa | `TVSetup` (168: `SATVActivationManager`, `BuddyWifiAutoJoiner`, 24 setup illustrations in `animations.tsv`); `oobe` (`OOBEActivity`, `RegistrationActivity`) |
| 13 | Account | Account page in Glass settings that shows who is signed in and links to Fire's sign-in screens. No second-account switching until the research item below proves it | not feasible | Keep `identity.auth.device.authorization`, `imp` (MAP), `ottssocompanionapp`, `venezia`, `tv.support`, `device.messaging` stack. MAP is device-wide (see account-center research) | `AuthKitUIService_tvOS`, `VideoSubscriberAccountViewService` (provider sign-in sheet), `TVAccessViewService`; `identity.*`, `settings.v2` `MyAccountActivity` |
| 14 | Parental / profiles | Glass profile switcher and PIN entry in Glass look, enforcement left to Fire | needs building | Keep `parentalcontrols` (enforcement: `PCONAdminReceiver`, `RestrictionsProvider`) and `profilepicker` (`PickerActivity`); Kids (`tahoe`) is removed (decision 9). Skin only | `TVRestrictionPINService` (6), `TVUserProfileService` (10), `PBRestriction*`, `PBLoretoUserProfileManager*`; `parentalcontrols` (`PINManagementActivity`), `profilepicker` |
| 15 | Sleep / wake | Sleep menu (now, timer), sleep-timer ring, wake transition, CEC hand-off, attention-based dim | needs building | Keep `devicecontrol` and `devicecontrolsettings` (CEC power, 58 components), `tv.arc`, `MtkArcInputService`, framework power. Glass issues the sleep key and shows UI; it does not own power | `PBAttentionMonitor*` state machines, `PBIdleAction`, `PREIdleSleepManager` (PreBoard), `TVSSSleepTimer*` (7), `SleepTimer` archive; `devicecontrol`, Glass Sleep Timer (sleep step unverified on Fire OS 8) |
| 16 | Notifications / banners | Glass banner stack and notification list fed by the notification listener; banners on top of apps via an overlay window | replace a Fire app | Replaces the UI of `tv.notificationcenter` (own uid, 11 components, count provider). Keep `uxnotification` (service), `alexanotifications`, `alexaalerts`: they post into it. SystemUI toasts stay | `PBBulletinManager`, `PBBulletinService`, `PBBulletinToBannerAdapter`, `BulletinBoard` (76), `TVSBIncomingCallBannerView`; `notificationcenter` (`NotificationCenterActivity`, `NotificationCountProvider`) |
| 17 | System alerts and dialogs | Skinned alert, confirm and power dialogs; remote-battery and headphone banners from Glass where a signal exists | not feasible | Stock SystemUI (`android.uid.systemui`: power dialog `GlobalActionsDialog`, volume, recents, keyguard) cannot be replaced by a privileged app. Only a static resource overlay can restyle it (unverified, section 3) | `PBCriticalAlertManager`, `PBDialogManager`, `PBHeadphoneBannerManager`, `PBCriticalRemoteBatteryAlertManager`; `systemui` (`globalactions` 40, `volume` 51, `recents` 15 classes, `TvSystemUIFactory`) |

**Status counts (17 rows): already in Glass 4, needs building 8, replace a Fire app 2, not feasible 3.**

Rows by status:
- Already in Glass: 1 Home, 2 Control Center, 8 Screensaver, 9 AirPlay.
- Needs building: 3 Settings, 4 TV, 5 Music, 7 Search, 11 Controllers, 12 Onboarding, 14 Parental/profiles, 15 Sleep/wake.
- Replace a Fire app: 6 Photos, 16 Notifications.
- Not feasible: 10 Siri, 13 Account, 17 System alerts.

Rows 10, 13 and 17 are "not feasible" as replacements. Each still has a skin task in the roadmap where a lever exists.

### Fire components that stay, whatever the status

These come straight from the spec's acceptance checklist and the package classification; the decompile confirms their roles.
- **DRM and streaming:** `venezia` (327 components: licensing, IAP, locker), `tv.support`, `ottssocompanionapp`, `device.messaging`, `tcomm`, WebView, Widevine and PlayReady HALs (native, not APKs).
- **Sign-in:** `imp` (MAP), `identity.auth.device.authorization`, `oobe`, `autopairservice`.
- **Alexa:** `vizzini`, `aria`, `alexa.datastore.app`, `csm.htmlruntime`, `alexadirectivebrokerservice`, `alexaalerts`, `androidskillconnectioncapability`.
- **Prime Video:** the Prime app plus everything under "DRM and streaming" and "Sign-in".
- **Platform surfaces under a system uid:** `systemui` (`android.uid.systemui`), `settings.core` and `cast.sink` (`android.uid.system`).

## 3. Constraints

**Hardware and OS.**
- Fire OS 8.1.8.2 is Android 11 (API 30), **32-bit userspace only**: `ro.zygote=zygote32`, ABI list `armeabi-v7a,armeabi`, no 64-bit list. Every native library Glass ships must be 32-bit ARM (the keymap tool is built for `arm-linux-musleabi`). Android 12+ APIs do not exist.
- MediaTek MT8696, Imagination GE9215 GPU, 2 GB RAM. Glass already lives inside a budget of about 120 MB PSS and an 8 MB release APK.
- `ro.control_privapp_permissions=enforce`: a privileged app missing one allowlist entry stops the boot. Every new priv-app needs a generated allowlist and a rollback ready.

**GPU rules (from the Glass project, measured on this GPU).**
- The GPU affords about **two full-screen blended passes per frame**. No full-screen translucent overlays. Wallpapers are opaque with the scrim baked in.
- Glass surfaces are one flat fill per surface over a pre-blurred backdrop. No clip paths, no stacked translucent passes; each extra shader-filled stroke cost about 7 ms per frame.
- No animated `shadowElevation`; use pre-blurred shadow bitmaps. Blurred text shadows only on small static text.
- Consequence for this map: any system-wide surface drawn over apps (banners, volume HUD, sleep menu, alerts) must be a small, opaque or tint-only panel, not a blurred full-screen glass. Anything that needs live blur of an arbitrary app behind it is out of budget; use a baked snapshot or a flat tint.
- Compose follows the animator scale; the stick runs at 1.0x because the motion table in section 5 is tuned to real timings.

**No emulator.** Fire OS cannot boot on Apple Silicon: its 32-bit-only userspace needs AArch32, which M-series cores lack, and the vendor image is MediaTek specific. The closest tool is the Android TV AVD (API 31): good for layout, focus, key logic and unit tests, not for look, motion, GPU, memory, Bluetooth, Alexa, DRM, or the Amazon packages. All system-surface work (rows 15 to 17 above all) therefore needs the real stick, which is shared with other sessions (take the stick lock).

**Verified boot.** dm-verity is decided **off** (decision 4), via Magisk `KEEPVERITY=false` on the boot image (path V-C). That is a plan, proven only at gate G3 with an unmodified system first. Until then, treat any edited system partition as potentially unbootable. The bootloader loader (`lk`), `lk_real`, `preloader`, `vbmeta`, `logo` and `recovery` are never written, which also means the **boot logo cannot be changed**.

**Install modes.**
- **Glass Pro (Magisk, now):** can add and replace files systemlessly: priv-apps with allowlists, `.replace` markers that hide `/system` packages, static overlays under the product overlay path, boot-time scripts, resetprop, sepolicy patches. Everything lives in `/data/adb`, so a factory reset wipes it.
- **Glass OS (image, later):** the same payload baked into system/vendor/product with partition sizes unchanged. The only things an image adds are survival of a data wipe and OOBE without Magisk, a distributable single flash, and edits to the platform-signed system apps. Per the install-mode study, "OS behaves like Pro" for every feature.

**Platform signature wall (the central constraint of this map).**
- Surfaces owned by `android.uid.systemui` or `android.uid.system` (SystemUI, `settings.core`, `cast.sink`) are signed with Amazon's platform key. A privileged app signed with another key cannot take their uid, their signature permissions, or their window types.
- Other Amazon surfaces (`notificationcenter`, `oobe`, `parentalcontrols`, `profilepicker`, `quicksettings.ui`, `screensaver`, launcher) run under their own uids and are replaceable or disableable like the launcher was.
- Some Amazon settings activities are guarded by a signature|privileged permission (`LAUNCHER_SETTINGS`). Glass is privileged but does not hold it, so it uses root to start them.
- A modified, re-signed SystemUI would lose every signature permission other Amazon packages grant to Amazon-signed callers. This is untested and treated as high risk.

**Retheming without replacing.** Static resource overlays already exist on this build in the product overlay path: 28 target `android`, 3 target `com.android.systemui` (icon packs), 3 target `com.android.settings`, 1 targets `com.amazon.tv.quicksettings.ui` (static, priority 1). So the mechanism works for the framework, SystemUI and one Amazon app. Not verified: whether `settings.v2`, `notificationcenter`, `oobe` or SystemUI expose an `<overlayable>` policy that accepts a product overlay for the resources we want (colours, dimens, strings, drawables, fonts). First task of phase 2 is one overlay on each, tested on the stick.

## 4. Fire-side risks found while mapping

- **F1: Alexa video search results use launcher activities.** `tv.launcher` handles actions such as showing text search and Alexa "display results" directives through `SearchResultsDeepLinkActivityDI` and `DirectiveSearchResultsActivityDI`. With the launcher disabled these may fail silently. Alexa itself works (tested), but video search and "show more" voice results were not tested. Check before claiming Alexa parity; the fix is for Glass to handle the same intent actions.
- **F2: Home key flash.** SystemUI plays a black fade of about 250 ms on a real Home press (gated by a perf-animation property, already off on the stick). It must stay off in every image.
- **F3: Settings key.** The remote's Settings button is swallowed by the key policy manager before apps see it. The Pro keymap rewrites the scan code; an image must bake the same rewrite or the quick panel cannot open over apps.
- **F4: Alexa depends on `aria`.** Removing it crashed every mic hold. Any debloat batch touching Alexa packages needs the Alexa check from the spec.
- **F5: Data wipe.** Pro lives in `/data/adb`; a wipe returns Fire's OOBE and Amazon's launcher. Until Glass OS is an image, onboarding must be written to be re-runnable.

## 5. Motion and feel constants

**Read this first.** `animations.tsv` holds the parameters of **baked Core Animation archives**: HUD glyphs, setup illustrations, system icons (7,713 rows; spring rows 3,027). It does **not** contain the live shell motion (focus lift, scroll, overlay open and close, app launch). Those are compiled code. Glass keeps the frame-measured values from a real device (Glass `Motion.kt`) for the shell; this file's springs are for **system glyphs and HUD icons** only. Do not swap shell springs for the values below.

Group counts below merge Dark, Light, black, RTL and Legacy variants and count distinct archive families, not rows (the single Sleep Timer glyph alone is 378 rows).

How to read the Compose columns: with CA mass m, stiffness k and damping c, Compose `stiffness = k / m` and `dampingRatio = c / (2 * sqrt(k * m))`. "Settle" is the archive's own duration field for the spring.

### 5a. Springs in system archives

| CA spring (m, k, c) | Compose stiffness | Compose damping ratio | Settle (archive) | Archive families | Where it appears | Glass use |
|---|---|---|---|---|---|---|
| 2, 300, 50 | 150 | 1.02 | 0.8 s | 62 (most common) | Do Not Disturb glyph, listening-mode glyphs, spatial audio glyphs, setup illustrations, calibration art | Default glyph spring: toggle glyphs, setup art |
| 1, 435, 25 | 435 | 0.60 | 0.597 s | 1 | Sleep Timer glyph scale | Sleep timer glyph pop |
| 2, 300, 30 | 150 | 0.61 | 0.998 s | 5 | Now Playing transport glyphs (forward/back, play/pause) | Now Playing transport glyphs |
| 2, 300, 36 | 150 | 0.73 | 1.0 s | 2 | Volume HUD glyph | Volume or mute glyph if Glass draws a HUD |
| 1, 845.74, 58.16 | 846 | 1.00 | 0.3175 s | 4 | Play/pause/stop snap, transport glyphs | Fast critically damped snap for button glyphs |
| 2, 250, 25 | 125 | 0.56 | 1.19 s | 2 | Assistant suggestions glyph | Voice suggestion glyph |
| 1, 300, 26 | 300 | 0.75 | 0.59 s | 1 | Mic toggle glyph | Mic or listening toggle |
| 1.4, 111, 11 | 79 | 0.44 | 1.86 s | 1 | Listening orb | Voice listening orb (softest, most bounce) |
| 3, 500, 1000 | 167 | 12.9 (overdamped, effectively a held pose) | 0.8 to 1 s | 3 | Settings wireless-audio-sync art and onboarding summary art | Not needed: it reads as a timed move, use a tween |

Two cross-checks against Glass:
- Glass focus-in uses stiffness 850 with damping ratio 0.65. The only archive spring near that stiffness (846) is critically damped. The shell's overshoot comes from live measurement, not from these archives. Keep Glass's value.
- The 2, 300, 50 spring (stiffness 150, damping ratio 1.02, 0.8 s) is slower and calmer than anything in the shell. It suits glyph transitions in system HUDs, not tile focus.

### 5b. Durations and easings in system archives

| Constant | Value | Where | Glass use |
|---|---|---|---|
| Fast fade or fill | 0.1 s and 0.2 s | blur/opacity steps in the autofill illustration | Chip and state-colour fades |
| Standard state change | 0.25 s (586 rows) | sign-in progress and icon bubble fills and opacity | Progress and badge state changes |
| Half-second fade | 0.5 s | reader-mode illustration opacity | Cross-fades of small art |
| Glyph pop | 0.64 s and 0.8 s | listening-mode glyph scale | Toggle glyphs |
| Spatial-audio loops | 1.5 s (540 rows), 2 s | head-tracked glyph loops | Looping indicators |
| Sleep Timer ring | 20 s stroke draw, with an opacity fade over the last 1% of the run | `SleepTimer` archive (PineBoard) | Sleep timer countdown ring; the archive is the 20 s variant, other lengths scale the same shape |
| Ease-out | cubic-bezier(0, 0, 0.25, 1) | autofill illustration | Default out-curve for small system UI |
| Expressive in-out | cubic-bezier(0.49, 0, 0.065, 1) | sign-in progress, icon bubble | Progress and bubble motion |
| Ease-in | cubic-bezier(0.75, 0, 1, 1) | autofill illustration exits | Dismissals |
| Symmetric in-out | cubic-bezier(0.42, 0, 0.58, 1) | reader-mode art | Generic in-out |
| Classic ease | cubic-bezier(0.25, 0.1, 0.25, 1) | audio-sync and reader art | Rarely; prefer the others |

### 5c. Shell constants that are not in the archive (Glass keeps its own measured values)

For completeness, so nobody looks for them in the TSV:

| Constant | Glass value today | Source |
|---|---|---|
| Focus in | spring, stiffness 850, damping ratio 0.65 (about 7% overshoot, peak near 130 ms) | frame-measured, `Motion.kt` |
| Focus out | spring, stiffness 500, damping ratio 1 | same |
| Vertical scroll | 700 ms, exponential-out, 90% by 350 ms | same |
| Focus label | 80 ms delay, 70 ms in, 130 ms out | same |
| Overlay open and close | 130 ms ease-out, exit mirrors | same |
| List row select | 33 ms in, 60 ms out | same |
| Page push | 200 ms slide plus fade | same |
| App launch | about 450 ms, exponential decelerate, starts 12% in | open item in Glass |

## 6. Naming to review (clean-room rule)

The rule is: no Apple product names as UI names in anything that ships. Names Glass uses today that need a decision by the user (reported, not changed here): "Control Center", "Aerials" (screensaver, feed and labels), "AirPlay" (quick panel tile and the PhairPlay add-on text), "Cover Flow", "Top Shelf", and README wording such as "Apple TV-style" and "tvOS-style". Neutral candidates used in this document: quick panel, idle screen, wireless receive, album browser, featured shelf. Class names in section 2 are evidence only and must never appear in a UI, resource name, or public docs page.

## 7. Roadmap

Everything that can be a Pro feature should be one: it ships earlier, is removable, and is tested on the stick. Efforts are rough, for one developer with the stick available, and are estimates, not measurements.

### Phase 0: what exists (Glass Pro v1, in progress)
Home, quick panel, remote keys, keepalive, tuning, systemless debloat, bundled store and browser. Rows 1, 2, 8, 9. Stick install steps still pending.

### Phase 1: Glass-only system surfaces (Pro; no platform risk)
Uses only privileged-app powers (overlay window, notification listener, accessibility, usage access, root).
- Row 16 Notifications: banner stack and list from the notification listener; hide or disable `notificationcenter` UI. About 1 to 2 weeks.
- Row 15 Sleep and wake: sleep menu, ring, wake transition, verify the sleep step on Fire OS 8. About 1 week.
- Row 3 Settings shell and row 14 profile/PIN skin over Fire's activities. About 2 weeks.
- Row 7 Search and row 4 Watch row (Watch Next, add-on feeds); fix F1 so Alexa search results open. About 2 weeks.
- Row 5 Now Playing screen and album browser (reuses existing Now Playing data). About 1 to 2 weeks.
- Row 6 Photos source and viewer, wired into the idle screen. About 1 to 2 weeks.
- Row 11 Controller toast, battery tile and pad navigation (gaming research, several parts unverified). About 1 to 2 weeks.
- Row 12 Re-runnable first-run flow after OOBE. About 1 week.

### Phase 2: retheme the platform surfaces (Pro; needs spike)
- Spike: one static overlay each on SystemUI, `settings.v2`, `notificationcenter`, `oobe`, `quicksettings.ui`; record which resources are accepted. About 3 to 5 days.
- If accepted: restyle row 17 (alerts, power dialog, volume) with colours, shapes, fonts and dimens only; layouts cannot change. Boot animation swap (assumed possible through a Magisk file replace; unverified; the `logo` partition is untouched). About 1 to 2 weeks.
- Keymap and the stock volume panel: research whether it can be suppressed so Glass draws its own HUD. Unknown.

### Phase 3: research that may stay "not feasible"
- Rows 10 and 13: a read-only study of how Alexa's overlay is drawn, what events it broadcasts, and whether Prime Video supports a second account. A skin or a second-account story is only planned if the study finds a lever. About 1 week each, no build promised.

### Phase 4: Glass OS image (needs the image)
Only items that need an image:
- Same payload baked in, so a factory reset and OOBE keep Glass and the keymap without Magisk (spec Track B; gate G3 for verity first).
- A single distributable flash and a deterministic build script.
- Edits to platform-signed system apps (SystemUI layouts, settings.core) if phase 2 shows overlays are not enough, with the re-signing risk above. Optional and last.
- Kernel and hardware tuning where the image work allows it (spec section 13).
Effort: tracks the existing Track B plan; the new work here is only the platform-app edits, about 2 to 4 weeks if attempted.

### Ordering rationale
Phase 1 first because it needs no unproven mechanism and each item is removable. The phase 2 spike is cheap and decides how far "whole system" can go without touching platform apps. Phase 3 stays research so it cannot block the rest. Phase 4 follows the existing plan's gates.

## 8. Biggest blocker

The platform signature wall. The stock volume, power dialog, recents, toasts and settings core live in SystemUI and `settings.core` under Amazon's system uids. A privileged Glass cannot replace them, only restyle them through static overlays whose coverage is unverified. If overlays are rejected, "whole system looks like tvOS" is capped at everything outside SystemUI, and the remaining path (patching and re-signing platform apps in an image) is untested and risks breaking Amazon's signature permissions.

## 9. Open items

1. Phase 2 overlay spike results per target app.
2. F1: Alexa video search results with the launcher disabled.
3. Sleep step on Fire OS 8 (Glass Sleep Timer is unverified).
4. Volume panel suppression.
5. Naming decisions in section 6.
6. Photo and music sources beyond MediaSession (licences and terms).
