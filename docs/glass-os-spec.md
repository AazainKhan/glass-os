# Glass Pro (tier 2) and Glass OS (tier 3) spec

Date: 2026-10-10 (revised same day with the user's answers in `decisions-2026-10-10.md`). Status: planning. Device: Fire TV Stick 4K 2nd Gen (karat, AFTKRT, MT8696), Fire OS 8.1.8.2, build 0032548774788, Magisk 30.7, amonet (kaeru LK + TWRP in recovery).

## 1. Goal

Two tracks, shipped in order (decision 2):

- **Track A, Glass Pro (tier 2):** one Magisk zip that merges `glass-system`, `glass-tuning`, `glass-remote-keys`, the two `service.d` scripts, a **systemless debloat** (Magisk replace of every REMOVE package dir), the bundled store and browser (section 10). Ships first: it installs from the Magisk app, needs no image flash, and is removed by uninstalling the module. Section 9.
- **Track B, Glass OS (tier 3):** the image rebuild below. Its removal list *is* Track A's list (same `config/remove-candidates.tsv`, same lint, same generator), so A is B's tested spec.

Track B goal: a rebuilt system image for the user's own stick in which:

- Amazon's launcher (`com.amazon.tv.launcher`, `com.amazon.firehomestarter`) and evidenced bloat (ads, telemetry/metrics, OTA updaters, shopping, tutorials) are **deleted from the image**, not just disabled.
- Glass (`dev.glasslauncher`, `~/Documents/glass-launcher`) is baked in as a privileged system app and is the home app.
- Everything the user relies on keeps working (section 4).
- The stick is recoverable at every step (section 6).

The public deliverable is `rom/build.sh`: a deterministic script that users run against **their own** OTA. No Amazon binaries are redistributed; the repo holds scripts, config lists and docs only.

## 2. Evidence this spec rests on

All from read-only analysis on the Mac (2026-10-10):

| Fact | Evidence |
|---|---|
| OTA is a full block OTA, non-A/B, dynamic partitions in `super` (group `main` 1623195648 B; system 1264836608, vendor 135172096, product 17121280). `super` is mmcblk0p14 = 1587200 KiB = 1625292800 B. | `work/dynamic_partitions_op_list`, `partitions.txt` |
| system/vendor/product are plain ext4 (no shared_blocks), filesystems fill the AVB data area exactly: system 303905×4096 = 1244794880 B with 919 free blocks; vendor 32459 blocks (105 free); product 4094 (13 free). Hashtree + FEC sit after the filesystem inside each partition. | `dumpe2fs -h`, `avbtool info_image vbmeta.img` |
| `system_ext` lives inside the system image (`/system/system_ext`); most Amazon apps are there. | `debugfs ls` |
| vbmeta (rollback index 2) holds hashtree descriptors for system/vendor/product and a chained descriptor for boot. Its digest `4688ffe0…3913` equals `ro.boot.vbmeta.digest` in `getprop.txt`: the stick ran exactly this OTA's vbmeta + boot when that snapshot was taken. | `avbtool calculate_vbmeta_digest` vs `getprop.txt` |
| dm-verity was active: `ro.boot.veritymode=eio`, `/` on dm-3, vendor dm-4, product dm-5; fstab has `avb=vbmeta`/`avb` on system/vendor/product, `first_stage_mount`. | `getprop.txt`, `vendor/etc/fstab.mt8696` |
| Bootloader reports locked/green (`ro.boot.flash.locked=1`, `vbmeta.device_state=locked`, `verifiedbootstate=green`) although amonet is installed: kaeru spoofs state (kaeru has fastboot, `oem` commands and AVB efuse reads). The snapshot (2026-10-06 15:16) may predate amonet/Magisk. | `getprop.txt`, `strings karat-kaeru.bin` |
| Recovery tooling on disk: amonet v1.3.0 ships `twrp.img` (karat TWRP, flashed to `recovery`), kaeru to `lk_real`, `boot-fastboot.sh`/`boot-recovery.sh` (bootrom handshake), `bootrom-step.sh read|flash <part> <file>` (BROM-level partition read/write). | `amonet-karat-v1.3.0/` |
| `vendor_flash_recovery` (`/vendor/bin/install-recovery.sh` + `vendor/recovery-from-boot.p`) can rewrite `recovery` from `boot` on boot. | `vendor/etc/init/*.rc` |
| `ro.control_privapp_permissions=enforce`: a priv-app missing an allowlist entry stops boot. | `system/build.prop`, `vendor/build.prop`, Glass `RootFeatures.kt` |
| Package graph: 280 APKs. Classification KEEP 194 / REMOVE 30 / INVESTIGATE 56 (whisperjoin.middleware.v2.np and spotify.mediabrowserservice moved to INVESTIGATE by the manager review). The removal lint passes with all 30 removed (re-run 2026-10-10); negative test (removing MetricsApi/MinervaApi) fails with 20+ errors. | `research/package-classification.md`, `tools/lint_removals.py` |

## 3. Design

### 3.1 What changes in the image

- **system** (includes system_ext): delete REMOVE packages' directories (batches 1-5, then promoted INVESTIGATE batches), add `/system/priv-app/GlassLauncher/GlassLauncher.apk` and `/system/etc/permissions/privapp-permissions-dev.glasslauncher.xml`.
- **vendor**: v1 optionally deletes `bin/install-recovery.sh` and `recovery-from-boot.p` (only if device check D5 shows it threatens TWRP).
- **product**: unchanged in v1.
- **boot**: the only boot change is Magisk's own re-patch with `KEEPVERITY=false` (section 3.3). LK, lk_real, preloader, tz, dtbo, vbmeta, logo, mcupm are **never written** by Glass OS. The OTA's `lk.bin`/`preloader.img`/`tz.img` would undo amonet and are excluded from all outputs.
- **Partition sizes and the super metadata stay identical.** Removals only free space; images are written at their original partition size. This avoids lpmake/metadata edits entirely in v1.

### 3.2 How images are edited

In place with e2fsprogs `debugfs -w` on a copy of the OTA's raw image, so every untouched inode keeps its owner, mode, timestamps and `security.selinux` xattr. Added files get mode/uid/gid set explicitly, `security.selinux=u:object_r:system_file:s0`, and all four timestamps set to 0x495c0780 (the stock value). Then `e2fsck -fn` must be clean. Rebuilding with `mke2fs -d` is rejected: `debugfs rdump` on macOS loses ownership and xattrs.

Determinism: same OTA + same config + same Glass APK → byte-identical images (fixed timestamps, edits applied in sorted order, no UUID/hash-seed change). `build.sh` refuses an OTA whose sha256 is not in `config/ota-allowlist.txt`.

### 3.3 Verified boot

Decided: dm-verity goes **off** (decision 4). Primary path (**V-C**): leave vbmeta, LK and stock verity metadata alone; re-patch boot with Magisk using `KEEPVERITY=false`, so magiskinit strips the `avb` flags from the first-stage fstab and init sets up no dm-verity for system/vendor/product. The edited partitions' stale hashtree is then never read. This depends only on Magisk, which already boots on this stick.

Fallback (**V-A**): regenerate hashtree+FEC for each edited partition with `avbtool add_hashtree_footer` (same partition size, salt and algorithm as stock) and build a new vbmeta with the new root digests. Used only if V-C fails; needs device check D1 to show kaeru accepts a vbmeta not signed with Amazon's key. V-B (vbmeta flag 2, "verification disabled") is a last option: libavb may ignore it while the state is spoofed as locked.

### 3.4 How images reach the stick

From TWRP (amonet's, in `recovery`): a flashable zip produced by `build.sh` checks `ro.product.device=karat`, checks the expected source build, maps logical partitions if TWRP has not, writes each image to `/dev/block/mapper/<name>` with `dd`, reads it back and compares sha256. Fallback: `fastboot flash super super.img` from kaeru fastboot with a full `super.img` built by `lpmake` (only if TWRP cannot write mapper devices; device check D10).

### 3.5 Glass integration

- Baked: Glass APK as priv-app + generated privapp allowlist (requested permissions ∪ Glass's `EXTRA_PRIVILEGED` list in `RootFeatures.kt`). The `glass-system` Magisk module is removed in the same step so there is one copy.
- Track A: all of these live in the Glass Pro module. Track B v1: Glass is baked; the rest stays in Glass Pro (installed without its debloat/priv-app parts, flag `GLASS_PRO_MODE=companion`) until baked in a later phase (decision 2).
- Stays in Magisk / `/data` for Track B v1 (they live outside the images and survive reflashing system): `glass-remote-keys` (needs a boot daemon re-applying the kernel keymap on every remote reconnect), `glass-tuning` (resetprop of ro.lmk.*), `/data/adb/service.d/start-launcher.sh`, `/data/adb/service.d/glass-remote-keepalive.sh`, Magisk su grant for Glass. Moving them into the image needs an SELinux domain for the daemon and is out of scope (open question Q2).
- Home: preferred home is stored in `/data`, so an in-place flash keeps Glass as home. After a data wipe, the boot script sets it. Remaining HOME-category packages after removal: android, tahoe, ftv.xpicker, tv.oobe, tv.settings.v2, whisperlink.core.android.

## 4. Must keep working (acceptance checklist)

| Function | Packages that carry it (KEEP) | Check |
|---|---|---|
| Boot to Glass | Glass, framework | `sys.boot_completed=1` < 120 s; HOME resolves to `dev.glasslauncher` |
| Wi-Fi | NetworkStack, connectivitycontroller, connection_manager_neo_service, cpl, wifi HAL | connected to saved network, ping |
| Bluetooth + remote, AutoPairService | Bluetooth, bluetoothpa, blepa, autopairservice, uxcontrollerservice, uxnotification, fireinputdevices, bluetoothkeymaplib | remote bonded after reboot; keepalive log line "stopping auto pair delay" |
| Alexa voice | vizzini, aria, alexa.datastore.app, csm.htmlruntime, alexadirectivebrokerservice, alexaalerts, androidskillconnectioncapability, imp, identity | hold mic, ask the time, answer shown; no vizzini crash in `logcat -b crash` |
| Streaming apps, DRM, sign-in | venezia, identity.auth.device.authorization, device.messaging(+SDKs), tcomm, ottssocompanionapp, tv.support, webview, Widevine/PlayReady HALs | Netflix + Prime Video + YouTube play 60 s; `dumpsys media.drm` lists Widevine |
| HDMI-CEC / volume | devicecontrol, devicecontrolsettings, tv.arc, MtkArcInputService, inputpreference, CEC HAL | remote volume changes TV volume; TV power follows stick |
| Screensaver path | ftv.screensaver (+ kso.blackbird, bueller.photos kept until investigated) | screensaver starts after the timeout; Glass Aerials still start |
| PhairPlay AirPlay | (3rd-party, `/data`) | iPhone sees the stick; video plays |
| Glass remote keys / keepalive / tuning | RemoteKeysService, Magisk modules | Glass e2e suite; app buttons map; `max_cached_processes=12` |
| Fire Settings, quick menu, keyboard, profiles, parental PIN | settings.v2/core, quicksettings.ui, tv.ime, profilepicker, parentalcontrols | open each from Glass |

## 5. Removal policy

- Only packages classified REMOVE, in numbered batches (`config/remove-candidates.tsv`): 1 tutorials, 2 already-disabled-with-no-fallout, 3 shopping/ads/stubs with no reverse dependencies, 4 telemetry/OTA services that declare widely-used permissions, 5 the Amazon launcher and home starter, 6 Kids (`com.amazon.tahoe`; decision 9; lint clean alone on 2026-10-10; profilepicker and parentalcontrols stay and must pass the checklist), 7 stock-Android leftovers (decision 6: Protips, PrintRecommendationService, BookmarkProvider and other AOSP apps with no TV use; list built in the plan), 8 Silk (`com.amazon.cloud9`) only after the replacement browser resolves `VIEW https://` URLs.
- `com.amazon.venezia` (Appstore) and the DRM/sign-in pieces stay (decision 10); the new store is added alongside.
- Both tracks use the same lists; a batch is promoted from Track A to Track B only after it has soaked in Track A.
- Batch 1 starts with a single package (`com.amazon.tmm.tutorial`) as the first ever image change.
- INVESTIGATE packages are promoted to a new batch only with written evidence (jadx/REA summary, lint green, a device disable-test of at least 24 h).
- Never removed: anything the lint marks as a required library or permission provider for a KEEP package, aria, venezia, imp/identity (MAP), the OOBE.

## 6. Recoverability

Three independent ways back, all prepared before the first write:
1. **From Android (root):** `dd` a backed-up partition image back (boot only; never system while mounted).
2. **From TWRP** (`adb reboot recovery`, or `amonet/boot-recovery.sh` if Android does not boot): `dd` backups to `by-name/boot` or `/dev/block/mapper/*` or the whole `by-name/super`.
3. **From BROM** (`amonet/bootrom-step.sh flash <part> <file>`), if TWRP itself is gone.

Full backup of every partition except `userdata`, streamed to the Mac with sha256 checked on both sides, and a restore rehearsal (section in plan, Gate G2) before any write.

## 7. Risks

| # | Risk | Mitigation |
|---|---|---|
| R1 | Hidden runtime coupling (the aria lesson): an app with few manifest dependants is needed at runtime. | Small batches; full checklist + e2e after each; rollback = previous system image. |
| R2 | Verity: an edited system with verity on reads as EIO → bootloop. | Gate G3 proves V-C with an unmodified system first. |
| R3 | privapp allowlist: missing entry for Glass → no boot. | Allowlist generated from the APK; test compares against `aapt2 dump permissions`; rollback ready. |
| R4 | `install-recovery.sh` overwrites TWRP, removing recovery path 2. | Device check D5; if it can, remove it from vendor (or confirm amonet already neutralised it). |
| R5 | Restoring super from TWRP while TWRP has partitions mapped. | Rehearsal in G2 uses read-compare plus an identical-byte write of `boot`; super restore writes whole `by-name/super` with nothing mounted. |
| R6 | Removing permission-declaring packages (minerva, launcher, OTA) leaves callers with SecurityExceptions. | Lint warns on any kept caller; batch 4/5 are separate gates. |
| R7 | Glass as a system app gets updated via `adb install -r` to /data; a signature change breaks updates. | Bake the same key Glass uses today (debug key); document. |
| R8 | Factory reset wipes `/data/adb` (modules, hosts, pm-disabled OTA services); OOBE then runs with the OTA updater alive, and an OTA's lk/preloader would undo amonet. | User agreed to one reset test (decision 5). It runs only on Track B **after** batch 4 has deleted the OTA packages from the image, with full backups proven, and with the stick's Wi-Fi offline during OOBE until Magisk is re-checked. Never on Track A. |
| R11 | Magisk replace hides only `/system` copies; a REMOVE package updated into `/data/app` keeps running. | Read-only check lists REMOVE packages with `/data/app` paths; each gets `pm uninstall` (updates only) before install. |
| R12 | A Glass Pro bootloop: the stick has no volume keys, so Magisk's key safe-mode is unreliable. | `adb wait-for-device shell magisk --remove-modules` during the loop; or TWRP `rm -rf /data/adb/modules/glass-pro`. TWRP reachability is proved before the first install. |
| R9 | Accidentally flashing the OTA's LK/preloader/tz undoes amonet; preloader writes can hard-brick. | build.sh never emits them; the flash zip refuses any partition not in {system, vendor, product}. |
| R10 | Redistribution of Amazon code. | Outputs go to `out/` (gitignored); repo has scripts and lists only; `leak-check` before publishing. |


## 8. Decisions (were open questions; answered 2026-10-10)

| Q | Decision |
|---|---|
| Q1 Amazon services | Prime Video and Alexa stay. Kids removed (batch 6). Silk replaced (batch 8, section 10). Music, Photos screensaver, Matter, video calling stay INVESTIGATE until triaged. Goal: every Amazon app swappable for an open-source one. |
| Q2 Bake remote-keys/tuning/keepalive | Magisk (Glass Pro) for Track A; baked into the image in a later Track B phase. |
| Q3 dm-verity off | Yes (V-C). |
| Q4 Factory-reset test | Yes, once backups are proven, under the R8 conditions. |
| Q5 BROM/recovery | User does not know how: we try from software first; physical steps in section 12. |
| Q6 Strip AOSP leftovers | Yes (batch 7). |
| Base OS | Stay Android/Fire OS (DRM, streaming). |

## 9. Track A: Glass Pro module

- One module id `glass-pro`, built by `rom/tools/glasspro/build.sh` into `out/glass-pro-<ver>.zip`, installable from the Magisk app or `magisk --install-module`.
- Contents: `system/priv-app/GlassLauncher` + allowlist (from glass-system), `post-fs-data.sh`/`service.sh` with the tuning (resetprop ro.lmk.*, zram 1.2 GB, max_cached_processes=12), the remote-keys daemon and keymap, the launcher start (HOME intent) and the remote keepalive (both from service.d), bundled store + browser (section 10), hosts file stays in its own module.
- Debloat: one empty dir with a `.replace` file per REMOVE package at its real path inside the module (`system/system_ext/priv-app/<Dir>/.replace`, product/vendor packages under `system/product`, `system/vendor`). Generated by `tools/replace_list.py` from `config/remove-candidates.tsv` + `manifests.json` with the same `--upto` and lint as Track B.
- Migration on install (`customize.sh`): marks `glass-system`, `glass-tuning`, `glass-remote-keys` for removal and moves `start-launcher.sh` and `glass-remote-keepalive.sh` out of `/data/adb/service.d` (into the module's backup dir) so nothing runs twice.
- `uninstall.sh`: restores `max_cached_processes=4`, Fire's key behaviour (as `scripts/remote-keys uninstall`), the two service.d scripts are not restored (they belonged to the old setup; documented), Amazon launcher re-enabled.
- Refuses to install unless `ro.product.device=karat` and Fire OS build matches the allowlist (a warning-only override flag for other builds, for contributors).

## 10. Replacement apps (evidence: `research/replacements.md`)

| Role | Choice | Ships as | Licence |
|---|---|---|---|
| Store (primary) | **Droid-ify** (F-Droid repos, Leanback entry, background updates, session/root installers) | upstream GitHub-release APK, unmodified, `/system/priv-app/Droidify` + privapp XML (`INSTALL_PACKAGES`, `DELETE_PACKAGES`) | GPL-3.0-or-later: ship licence + source link in module README |
| Store (optional) | Obtainium, with a preloaded app list for GitHub-only TV apps | first-run install from inside Droid-ify (not bundled) | GPL-3.0 |
| Browser | **TV Bro** `generic-geckoExcluded` build (system WebView, lowest RAM) | upstream APK unmodified, `/system/app/TVBro` | custom BSD-like: unmodified binaries only |
| Not chosen | Aurora Store (Play anonymous accounts: ToS/breakage risk; users can install it from Droid-ify) | — | GPL-3.0 |

APK sha256 and version are pinned in `config/bundled-apps.tsv`; the build downloads, verifies and never re-signs them, so in-app updates keep working.

## 11. Account center (evidence: `research/account-center.md`)

Verdict: **partially feasible, unproven for Prime Video.** MAP (`com.amazon.imp`) supports secondary accounts, child apps and per-app isolation, but Alexa uses the device (primary) account and there is no supported path to sign Prime Video into another one. Next step is a 1-day read-only check of the installed Prime Video APK for isolation support; only if present, a 3-6 day prototype of a secondary registration. No account-center UI is planned until then.

## 12. Device access (recovery/BROM)

Order, software first:
1. `adb reboot recovery` → `adb get-state` = `recovery` means TWRP is there (amonet put it in `recovery`; D5 compares hashes).
2. If Android does not boot: amonet `boot-recovery.sh`. This is a **preloader** handshake over USB serial (it waits for a new serial port, then sends `FACTORYM`), not BROM, and needs no case opening.
3. `bootrom-step.sh read|flash` also runs in preloader mode (`main.py` refuses otherwise) and is the last path if TWRP itself is gone.

Physical steps the user does only if 2 or 3 is needed:
1. Unplug the stick from its power adapter. Leave HDMI in if convenient.
2. Connect the stick's micro-USB port to the Mac with a **data** micro-USB cable (the Amazon power cable may be charge-only), through no hub.
3. On the Mac, start the script (`./boot-recovery.sh`); it prints "Waiting for device".
4. Plug the cable into the stick (powers it on). Within a few seconds the script logs "Found port" and "Preloader ready".
5. Once the script ends, the stick boots to TWRP on the TV; move the stick back to its power adapter only after we say so.
Opening the case to short a test point (true BROM) is needed only if the preloader itself is damaged; Glass never writes the preloader, so this is out of scope.

## 13. Later phase: kernel and hardware

Achievable without a new kernel build: cpufreq governor and min/max per cluster, I/O scheduler, read-ahead, zram size/algorithm, lmkd props, GPU devfreq governor (all via Glass Pro `service.sh`, measured with `scripts/perf-gate`). Kernel cmdline via the boot header is possible but kaeru/LK may override it: D1 compares `/proc/cmdline` with the boot header before relying on it. A rebuilt kernel needs Amazon's GPL source drop for karat (to locate) and is not planned.
