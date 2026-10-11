# Glass Pro and Glass OS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Track A ships Glass Pro, one Magisk zip (Glass priv-app, tuning, remote keys, keepalive, launcher start, systemless debloat, bundled Droid-ify and TV Bro). Track B then ships a deterministic `rom/build.sh` that turns the user's own karat OTA into system/vendor/product images with Amazon's launcher and evidenced bloat deleted and Glass baked in as the privileged home app, then flash it in gated batches without ever losing a way back.

**Architecture:** One removal list (`config/remove-candidates.tsv`) and one generator (`tools/replace_list.py`) feed both tracks: Magisk `.replace` markers for Glass Pro, `debugfs` deletions for Glass OS. Track B: edit the OTA's raw ext4 images in place with `debugfs -w` (keeps every stock inode, owner and SELinux label), keep partition sizes and super metadata unchanged, turn dm-verity off through Magisk's `KEEPVERITY=false` boot re-patch, and write images from amonet's TWRP to `/dev/block/mapper/*` with read-back verification. A manifest-graph lint gates every removal list.

**Tech Stack:** bash, Python 3 (`python3 -I`), e2fsprogs (`/opt/homebrew/opt/e2fsprogs/sbin`), brotli, sdat2img, aapt2 (`~/Library/Android/sdk/build-tools/36.0.0/aapt2`), avbtool.py (pinned), adb/fastboot (`../platform-tools`), Magisk 30.7 `boot_patch.sh` (on device), TWRP (amonet v1.3.0), bats-core for script tests, pytest for Python tools.

**Spec:** `rom/docs/glass-os-spec.md`. Decisions: `rom/docs/decisions-2026-10-10.md` (authoritative). Evidence: `rom/research/package-classification.md`, `rom/research/replacements.md`, `rom/research/account-center.md`, `rom/research/inventory.md`, `rom/research/tooling.md`.

## Global Constraints

- Source OTA: `update-kindle-karat-RS8182_user_3811_0032548774788.bin`, sha256 starting `559cddbc`; fingerprint `Amazon/karat/karat:11/RS8182.3811N/0032548774788:user/amz-p,release-keys`.
- Partition sizes never change: system 1264836608, vendor 135172096, product 17121280 (bytes). Filesystem sizes: system 303905, vendor 32459, product 4094 blocks of 4096.
- Glass Pro writes only `/data/adb` (its module dir, removal markers on the three old modules, the moved service.d scripts). Glass OS writes only `system`, `vendor`, `product` (and `boot` only via Magisk re-patch in Task 17). Never `lk`, `lk_real`, `preloader`/`mmcblk0boot0`, `tee1/2`, `dtbo`, `vbmeta`, `recovery`, `logo`, `mcupm`, `gpt`.
- Added files: owner 0:0, dirs 0755, files 0644, `security.selinux=u:object_r:system_file:s0`, timestamps 0x495c0780.
- `ro.control_privapp_permissions=enforce`: every priv-app needs a complete allowlist.
- Keep `com.amazon.aria`, `com.amazon.venezia`, `com.amazon.imp`, OOBE, and every package the lint lists as a library/permission provider. AOSP leftovers may be removed (batch 7).
- Bundled third-party APKs are upstream binaries, pinned by sha256, never re-signed or modified (TV Bro licence; in-app updates).
- No Amazon binaries in git: `input/`, `work/`, `out/`, `backup/` are gitignored. Docs summarise decompiled code; they never quote it.
- Commits: Conventional Commits `type(scope): summary`, ending with the Co-Authored-By line from the session.
- The stick is shared: take `~/Documents/glass-launcher/scripts/stick-lock hold glass-os --max 60 -- <cmd>` for every device step; tell the Glass agents before reboots.
- Device steps that write anything need the user's OK at the gate (G2-G7, GA1, GA2.x). Read-only checks (Task 8) don't.
- Order: Tasks 1-13 (shared + Track A) before 14-22 (Track B). Track B batches are promoted only after the same batch soaked in Glass Pro.

## Review Focus

1. **A partition write that lands on the wrong block device** (by-name vs mapper, super while mapped): flash zip refuses unknown partitions and size mismatches. Test in Task 16 (`refuses_unknown_partition`, `refuses_size_mismatch`).
2. **Glass Pro installed over the old modules runs things twice** (second Glass instance, double keymap daemon): Task 6 `customize_marks_old_modules_for_removal`, `customize_moves_service_d_scripts`, `service_starts_home_once`; Task 10 Step 4 single-process check.
3. **A REMOVE package updated into `/data/app` survives Magisk replace**: D12 in Task 8, handled in Task 10 Step 1.
4. **Backup images that are truncated or silently differ**: Task 9 `backup_hash_mismatch_fails`.
5. **A bundled APK that is re-signed or requests an unlisted privileged permission** (bootloop under enforce, broken updates): Task 5 `apk_not_resigned`, `priv_apk_gets_xml`; Task 4 `allowlist_covers_requested`.

Also pinned: unknown OTA (Task 15 `rejects_unknown_ota`), system_ext symlink paths (Task 14 `removes_system_ext_package_via_real_path`, Task 3 `test_system_ext_maps_to_system_prefix`).

---

## File Structure

Track B files as before (`build.sh`, `tools/img_edit.py`, `tools/flashzip/`, `tools/backup.sh`, `tools/device-checks.sh`, `tools/smoke.sh`), plus: `tools/replace_list.py` (Task 3), `config/bundled-apps.tsv` + `tools/fetch_apps.sh` + `THIRD_PARTY.md` (Task 5), `tools/glasspro/` (Task 6). Docs site: see `docs/docs-site-plan.md`.

---

## Shared groundwork (Mac only)

### Task 1: Repo, ignore rules, pinned tools

**Files:**
- Create: `rom/.gitignore` (replace), `rom/tools/fetch-tools.sh`, `rom/tests/test_fetch_tools.bats`

**Interfaces:**
- Produces: `tools/bin/avbtool.py` (pinned), env file `tools/env.sh` exporting `E2FS=/opt/homebrew/opt/e2fsprogs/sbin`, `AAPT2`, `AVBTOOL`.

- [ ] **Step 1:** `cd ~/Documents/firestick-unlocked/rom && git init && git config user.email "$(git -C ~/Documents/glass-launcher config user.email)"`. Expected: `Initialized empty Git repository`.
- [ ] **Step 2:** `.gitignore` = `input/ work/ out/ backup/ tools/bin/ *.img *.bin *.apk *.zip`. Verify: `git check-ignore -v work/system.img input/x.bin` prints both.
- [ ] **Step 3:** Write failing test `tests/test_fetch_tools.bats`: `fetch-tools.sh` with a wrong expected sha exits 1 and leaves no `tools/bin/avbtool.py`.
- [ ] **Step 4:** Implement `fetch-tools.sh`: download `https://android.googlesource.com/platform/external/avb/+/<COMMIT>/avbtool.py?format=TEXT`, base64-decode, check sha256 against a constant; pin `<COMMIT>` to the current `main` commit id (record it in the script). `android11-release` is unusable (its `avbtool.py` is a symlink stub).
- [ ] **Step 5:** `bats tests/test_fetch_tools.bats` → PASS; `python3 -I tools/bin/avbtool.py info_image --image work/vbmeta.img | grep -c 'Hashtree descriptor'` → `3`.
- [ ] **Step 6:** Commit `build(rom): init repo, ignore images, pin avbtool`.

### Task 2: Package DB, graph and removal lint as tested tools

**Files:**
- Modify: `rom/tools/manifest_db.py` (add `main(apk_root, out_json)` that runs aapt2 itself), `rom/tools/lint_removals.py`
- Create: `rom/tools/graph.py`, `rom/tests/test_lint.py`, `rom/tests/fixtures/` (tiny hand-written manifests.json + libs_features.txt, no Amazon data)

**Interfaces:**
- Produces: `manifest_db.py <extracted_root> <manifests.json>`; `graph.py <manifests.json> <libs_features.txt> <graph.json>`; `lint_removals.py <manifests.json> <libs_features.txt> <remove.tsv> [--upto N]` exit 0/1, lines `ERROR …`, `WARN …`, `HOME candidates after removal: [...]`.

- [ ] **Step 1:** Tests in `test_lint.py` against fixtures: `test_required_lib_from_removed_apk_errors` (exit 1, line contains `requires library`), `test_optional_lib_ok`, `test_guarded_component_warns` (kept caller listed), `test_unknown_package_errors` (`not in image`), `test_upto_limits_batches`.
- [ ] **Step 2:** `python3 -m pytest -q tests/test_lint.py` → the WARN/upto tests fail until fixtures and `--upto` parsing are wired.
- [ ] **Step 3:** Make them pass; keep the lib-owner match on the APK path below `system_ext/` or `system/` (the libs file uses both `/system_ext/…` and `/system/system_ext/…`).
- [ ] **Step 4:** Real-data check: `python3 -I tools/lint_removals.py work/manifests.json work/libs_features.txt config/remove-candidates.tsv` → `30 removed, 0 errors`, no WARN lines. Negative: a tsv with `com.amazon.minerva.client.api` → exit 1.
- [ ] **Step 5:** Commit `feat(rom): manifest graph and removal lint with tests`.

### Task 3: Shared replace-list generator and new batches

**Files:**
- Create: `rom/tools/replace_list.py`, `rom/tests/test_replace_list.py`
- Modify: `rom/config/remove-candidates.tsv` (add batches 6-8), `rom/config/classification.tsv`

**Interfaces:**
- Consumes: `manifests.json` (`file` field), `remove-candidates.tsv`, lint from Task 2.
- Produces: `replace_list.py <manifests.json> <remove.tsv> --upto N [--format magisk|paths]` → sorted lines. `magisk`: module-relative dirs (`system/system_ext/priv-app/<Dir>`, `system/product/app/<Dir>`, `system/vendor/app/<Dir>`); `paths`: image paths for Task 14 (`/system/system_ext/priv-app/<Dir>`). Both tracks call only this.

- [ ] **Step 1:** Tests with fixtures: `test_system_ext_maps_to_system_prefix`, `test_product_maps_under_system`, `test_upto_filters`, `test_same_set_both_formats` (paths and magisk differ only in prefix), `test_unknown_pkg_errors`.
- [ ] **Step 2:** FAIL → implement → PASS.
- [ ] **Step 3:** Batches: 6 = `com.amazon.tahoe` (Kids); 7 = AOSP leftovers, chosen by listing non-`com.amazon` packages in `manifests.json` with no TV use (start: Protips, PrintRecommendationService, BookmarkProvider; add others only with a one-line reason each); 8 = `com.amazon.cloud9` (Silk). Run lint `--upto 8` → 0 errors; HOME candidates must still include `com.amazon.tv.settings.v2` and must not lose `profilepicker`/`parentalcontrols` from the image.
- [ ] **Step 4:** Commit `feat(rom): shared replace list and kids/aosp/silk batches`.

### Task 4: Glass priv-app allowlist generator

**Files:**
- Create: `rom/tools/privapp_xml.py`, `rom/tests/test_privapp.py`

**Interfaces:**
- Produces: `privapp_xml.py <glass.apk> > privapp-permissions-dev.glasslauncher.xml`; requested permissions from `aapt2 dump permissions`, union `EXTRA_PRIVILEGED` parsed from `~/Documents/glass-launcher/app/src/main/java/dev/glasslauncher/system/RootFeatures.kt` (fail if the constant cannot be found), sorted, same XML shape as `RootFeatures.installSystemApp`.

- [ ] **Step 1:** `test_allowlist_covers_requested`: every `uses-permission` from `aapt2 dump permissions app-release.apk` appears in the XML; `test_sorted_and_stable`: two runs identical; `test_missing_extra_list_fails`.
- [ ] **Step 2:** Run → FAIL. **Step 3:** implement. **Step 4:** PASS. Cross-check against the live module later (Task 8, D7).
- [ ] **Step 5:** Commit `feat(rom): generate Glass privapp allowlist from the APK`.

### Task 5: Bundled apps: pinned download and allowlists

**Files:**
- Create: `rom/config/bundled-apps.tsv` (name, url, sha256, versionName, dest dir, priv yes/no), `rom/tools/fetch_apps.sh`, `rom/tests/test_fetch_apps.bats`, `rom/THIRD_PARTY.md` (licences + source links, from `research/replacements.md`)

**Interfaces:**
- Consumes: Task 4 `privapp_xml.py <apk> [--extra-from <kt>]` (the Kotlin extra list optional for non-Glass APKs).
- Produces: `fetch_apps.sh <outdir>` → `<outdir>/<Dest>/<Name>.apk` for Droid-ify (`priv-app`) and TV Bro geckoExcluded (`app`), plus `privapp-permissions-<pkg>.xml` for each priv APK.

- [ ] **Step 1:** Tests: `wrong_sha_fails_and_leaves_nothing`, `priv_apk_gets_xml`, `non_priv_apk_has_no_xml`, `apk_not_resigned` (`apksigner verify --print-certs` digest equals upstream digest recorded in the tsv).
- [ ] **Step 2:** FAIL → implement → PASS. The Droid-ify XML must contain `android.permission.INSTALL_PACKAGES` and `DELETE_PACKAGES` and every other privileged permission `aapt2 dump permissions` lists; no Android 12+ permission names.
- [ ] **Step 3:** Commit `feat(rom): pinned bundled store and browser`.

---

## Track A: Glass Pro (Magisk, tier 2)

### Task 6: Glass Pro module build

**Files:**
- Create: `rom/tools/glasspro/build.sh`, `rom/tools/glasspro/{module.prop,customize.sh,post-fs-data.sh,service.sh,uninstall.sh}`, `rom/tests/test_glasspro.bats`
- Read (do not change): `~/Documents/glass-launcher/scripts/{remote-keys,tuning}`, the two service.d scripts (copies via D12 in Task 8, or from the glass-launcher repo if they live there).

**Interfaces:**
- Consumes: Tasks 3, 4, 5; Glass APK path.
- Produces: `glasspro/build.sh --upto N --glass <apk> [--mode full|companion] --out out/` → `out/glass-pro-<ver>-b<N>.zip` + `out/glass-pro.SHA256`. `companion` = no debloat and no Glass priv-app (for Track B).

- [ ] **Step 1:** Tests (bats, zip inspected with `unzip -l`/`unzip -p`; scripts run with `MODPATH`, `GETPROP`, `ADB_DATA=$BATS_TMPDIR/data` overrides):
  - `zip_has_replace_markers_for_batch` (every `replace_list.py --format magisk --upto N` dir has a `.replace` file, nothing else);
  - `companion_has_no_replace_and_no_glass`;
  - `customize_marks_old_modules_for_removal` (creates `remove` in glass-system, glass-tuning, glass-remote-keys);
  - `customize_moves_service_d_scripts` (start-launcher.sh and glass-remote-keepalive.sh gone from service.d, present in `$MODPATH/backup/`);
  - `customize_refuses_wrong_device` (`ro.product.device=mantis` → abort);
  - `uninstall_restores_cached_processes_4` and `uninstall_calls_remote_keys_restore`;
  - `service_starts_home_once` (launcher start uses the HOME intent, never `am start -n`);
  - `reproducible` (two builds → same sha).
- [ ] **Step 2:** FAIL → implement → PASS. Port the tuning/remote-keys/service.d logic by copying, not rewriting; diff each ported script against its source in the commit body.
- [ ] **Step 3:** Commit `feat(rom): Glass Pro magisk module`.

### Task 7: Smoke checks script


**Files:**
- Create: `rom/tools/smoke.sh`, `rom/tests/test_smoke.bats` (fake adb fixtures)

**Interfaces:**
- Produces: `smoke.sh [--manual]` exit 0 when all automatic checks pass; prints the manual checklist (spec section 4) with `--manual`.

- [ ] **Step 1:** Tests with canned adb output: `fails_on_vizzini_crash` (`logcat -b crash -d` contains `com.amazon.vizzini`), `fails_when_home_not_glass`, `passes_on_good_device`.
- [ ] **Step 2:** FAIL → implement → PASS. Automatic checks: boot completed < 120 s; HOME resolves to `dev.glasslauncher`; `dumpsys wifi | grep -q 'mNetworkInfo.*CONNECTED'`; remote bonded (`dumpsys bluetooth_manager | grep -i 'Fire TV Remote'`); `dumpsys media.drm` lists widevine; `dumpsys hdmi_control` shows CEC enabled; no `FATAL EXCEPTION` for KEEP packages in `logcat -b crash -d`; `pm list packages` contains every KEEP package from `config/classification.tsv` and none of the removed batch; remote-keys daemon active (glass-pro module, or glass-remote-keys before Task 10); `settings get global activity_manager_constants` contains `max_cached_processes=12`.
- [ ] **Step 3:** Run once on the current stick (stock image) and keep the output as the baseline in `research/smoke-baseline.txt`. Commit `test(rom): device smoke checks`.


### Task 8: Read-only device checks (no gate needed)

**Files:**
- Create: `rom/tools/device-checks.sh`, `rom/research/device-checks.md`

**Interfaces:**
- Produces: `device-checks.sh > research/device-checks.md` (each check: command, raw value, verdict).

- [ ] **Step 1:** Implement the checks; each is `adb shell` read-only or `su -c` reading only:
  - D1 boot state: `getprop | grep -E 'ro.boot.(verifiedbootstate|flash.locked|vbmeta|veritymode)'`, `su -c cat /proc/cmdline`.
  - D2 layout: `ls -l /dev/block/by-name /dev/block/mapper`, `su -c blockdev --getsize64 /dev/block/by-name/super`, `su -c lpdump` (metadata slots, alignment, free space in `main`).
  - D3 Magisk boot config: `su -c magisk -v`; stream `boot` to the Mac (`adb exec-out su -c 'dd if=/dev/block/by-name/boot bs=4M'`), sha256 vs `work/boot.img`; if different, it is Magisk-patched: read `KEEPVERITY` from its ramdisk `.backup/.magisk` (`7z x` + `cpio -t`).
  - D4 verity now: `su -c dmctl list devices`, `su -c dmctl table system` (verity target present?).
  - D5 recovery: stream `recovery`, compare sha with `amonet-karat-v1.3.0/amonet/bin/twrp.img`; `getprop init.svc.vendor_flash_recovery`; `su -c cat /cache/recovery/last_install` if present.
  - D6 bootloader: sha of `lk`, `lk_real` vs `work/images/lk.bin` and `karat-kaeru.bin`.
  - D7 Glass: `dumpsys package dev.glasslauncher | grep -E 'codePath|versionName|signatures|privateFlags'`; `su -c cat /data/adb/modules/glass-system/system/etc/permissions/*.xml` (diff with Task 4 output).
  - D8 packages: `pm list packages -d`, `pm list packages -s | wc -l`, `cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME`.
  - D9 SELinux/prop: `getenforce`, `getprop ro.control_privapp_permissions`.
  - D10 (from TWRP, after the user OKs a reboot to recovery): `adb shell ls /dev/block/mapper; which lptools dmctl dd sha256sum blockdev`.
  - D11 device access: software-first order from spec section 12; `boot-recovery.sh` only if Android does not boot (then the user follows the physical steps in spec section 12).
  - D12 `/data/app` shadows: `pm list packages -f` filtered to `replace_list.py` packages; any `/data/app` path is listed for `pm uninstall` (spec R11).
  - D13 current Glass setup: copy `/data/adb/service.d/*.sh` and `/data/adb/modules/glass-*/` (scripts only) to `rom/work/current-setup/` as the porting source for Task 6.
- [ ] **Step 2:** Run under the stick lock; commit `docs(rom): device check results`.
- [ ] **Step 3 (user OK, reboot): device access proof.** `adb reboot recovery`; `adb get-state` → `recovery`; run D10; `adb reboot`. This gates Track A (rescue path for spec R12) as well as Track B.
- [ ] **Step 4: Gate G1.** Decide V-C vs V-A (spec 3.3) and the flash path (TWRP mapper vs fastboot super) from D3/D4/D10. If D5 shows `recovery` ≠ TWRP or install-recovery active, add `--vendor-no-install-recovery` to every build. Record the decision in `research/device-checks.md`.

### Task 9: Full backup and tested restore (Gate G2)

**Files:**
- Create: `rom/tools/backup.sh`, `rom/tests/test_backup.bats`, `rom/backup/<date>/` (gitignored)

**Interfaces:**
- Produces: `backup.sh <dir>` → one `<part>.img` per `/dev/block/by-name` entry except `userdata`, plus `mmcblk0boot0.img`, `mmcblk0boot1.img`, `gpt-primary.bin` (first 34 sectors of mmcblk0), `SHA256SUMS.device` and `SHA256SUMS.mac`.

- [ ] **Step 1:** Test with a fake `adb` on PATH: `backup_hash_mismatch_fails` (fake returns altered bytes → exit 1), `skips_userdata`, `binary_safe` (bytes 0x0a/0x0d survive; use `adb exec-out`, never `adb shell`).
- [ ] **Step 2:** FAIL → implement → PASS.
- [ ] **Step 3:** Run on the stick: `tools/backup.sh backup/2026-10-XX`. Expected: every line of the two SHA256SUMS files matches; `super.img` is 1625292800 B.
- [ ] **Step 4:** Consistency proof (Mac): extract `system` from `backup/…/super.img` using D2's lpdump extents (`dd skip=`), sha256 equals `work/system.img` sha256 (device runs this OTA). Same for vendor/product.
- [ ] **Step 5:** Copy the backup to a second disk; record both paths in `research/device-checks.md`.
- [ ] **Step 6 (needs user OK): restore rehearsal.** `adb reboot recovery`; in TWRP: `sha256sum /dev/block/by-name/boot` equals backup; `dd if=/tmp/boot.img of=/dev/block/by-name/boot` with the backup copy (identical bytes), re-hash equal; `dd if=/dev/block/mapper/system | sha256sum` equals backup system extent; reboot to Android; `sys.boot_completed=1`.
- [ ] **Step 7: Gate G2** = steps 3-6 green. Required before Task 10 (first Glass Pro install) and every Track B write. Commit `feat(rom): partition backup with dual hashing`.

### Task 10: Glass Pro install, batch 1a (Gate GA1)

- [ ] **Step 1:** Pre-checks (read-only): G2 green; D5/D10 show TWRP reachable (Task 8 Step 3); D12 lists no REMOVE package with a `/data/app` path (else `pm uninstall <pkg>` removes the update only, with user OK).
- [ ] **Step 2:** `tools/glasspro/build.sh --upto 1a --glass <apk> --out out/ga1` (batch 1a = `com.amazon.tmm.tutorial` only, as in Task 18).
- [ ] **Step 3 (user OK):** `adb push out/ga1/glass-pro-*.zip /data/local/tmp/`; `adb shell su -c 'magisk --install-module /data/local/tmp/glass-pro-*.zip'`; reboot.
- [ ] **Step 4:** `su -c magisk --list-modules` (or `ls /data/adb/modules`) shows only glass-pro + hosts module; `pm list packages | grep -c tmm.tutorial` → `0`; `ls /data/adb/service.d` has neither old script; `tools/smoke.sh` → 0; `scripts/e2e --stick` no new failures; Glass is a single process (`pidof dev.glasslauncher | wc -w` → 1).
- [ ] **Rollback:** `adb shell su -c 'touch /data/adb/modules/glass-pro/remove'` + reboot, then re-install the three old modules from `~/Documents/glass-launcher/scripts` and restore the two service.d scripts from the module's `backup/`. Bootloop: `adb wait-for-device shell magisk --remove-modules`; else TWRP `rm -rf /data/adb/modules/glass-pro`.
- [ ] **Step 5: Gate GA1.** Commit `feat(rom): Glass Pro batch 1a on device`.

### Task 11: Glass Pro batches 1b-8 (Gates GA2.1-GA2.8)

For each batch N in order (1b, 2, 3, 4, 5, 6 Kids, 7 AOSP, 8 Silk):
- [ ] **Step 1:** Lint `--upto N` → 0 errors; `build.sh --upto N`; update the module (`magisk --install-module` replaces it); reboot.
- [ ] **Step 2:** `smoke.sh` + `e2e --stick` + manual checklist. Batch 4/5 also need the 24 h soak (see Task 19 Step 3). Batch 6: open profiles and parental-PIN from Glass. Batch 8 only if `cmd package resolve-activity -a android.intent.action.VIEW -d https://example.com` resolves to TV Bro before the build. Bundled-app checks: Droid-ify installs and updates an F-Droid app with no prompt; TV Bro opens a page and its cursor moves with the D-pad.
- [ ] **Step 3:** Commit `feat(rom): Glass Pro batch N`. Rollback: install the previous batch's zip.

### Task 12: INVESTIGATE triage (repeat per package group)

- [ ] **Step 1:** For one group (e.g. ads/promo: kso.blackbird, tv.easyupgrade, tigris), use jadx/REA (`rea` android provider: `inspect_android_package`, `project_android_application_graph`) to answer: what binds to it, what it binds to, what breaks without it. Write a 5-line summary per package in `research/investigate/<pkg>.md` (no code quotes).
- [ ] **Step 2:** On the stick, `pm disable-user` it for 24 h, run smoke + manual checklist; append to `DEBLOAT-LOG.md`.
- [ ] **Step 3:** If clean, move it to a new batch (9+) in `remove-candidates.tsv` and go through Task 19. Otherwise mark KEEP with the reason.

### Task 13: Glass Pro release (tier 2)

- [ ] **Step 1:** `THIRD_PARTY.md` complete; module README: install from Magisk app, migration notes, uninstall, the two rescue commands (spec R12).
- [ ] **Step 2:** Leak check (`~/Documents/glass-launcher/scripts/leak-check` or the Task 22 greps) on the rom repo; zip contains no Amazon file (`unzip -l` shows only scripts, `.replace` markers, Glass, Droid-ify, TV Bro).
- [ ] **Step 3:** Publish only with the user's OK. Commit `docs(rom): Glass Pro release notes`.

---

## Track B: Glass OS (image, tier 3)

### Task 14: In-place image editor

**Files:**
- Create: `rom/tools/img_edit.py`, `rom/tests/test_img_edit.bats`

**Interfaces:**
- Consumes: manifests.json (`file` field gives each package's APK path).
- Produces: `img_edit.py remove <image> <manifests.json> <pkg>...` and `img_edit.py add <image> <src_file> <dest_path> [--mode 0644]`; both write a debugfs script to stdout with `--dry-run`, otherwise run `$E2FS/debugfs -w -f <script> <image>` then `$E2FS/e2fsck -fn <image>` and exit non-zero if e2fsck reports anything.

- [ ] **Step 1:** Tests on a copy (`cp work/system.img $BATS_TMPDIR/s.img`): `removes_package_dir` (after `remove … com.amazon.tmm.tutorial`, `debugfs -R 'ls /system/system_ext/priv-app' ` lacks it), `fsck_clean_after_remove`, `free_blocks_increase` (dumpe2fs Free blocks > 919), `removes_system_ext_package_via_real_path`, `add_sets_owner_mode_label_time` (debugfs `stat` shows 0644, uid 0, ctime 0x495c0780; `ea_get … security.selinux` = `u:object_r:system_file:s0`), `deterministic` (two runs from the same copy → same sha256).
- [ ] **Step 2:** Run → FAIL (no tool).
- [ ] **Step 3:** Implement. Removal walks the package dir depth-first from `debugfs -R 'ls -p <dir>'` and emits `rm` for files, `rmdir` for dirs (including `oat/arm/*`). Add emits `mkdir`, `write`, `set_inode_field <p> mode 0100644`, `uid 0`, `gid 0`, `{a,c,m,cr}time 0x495c0780`, `ea_set <p> security.selinux "u:object_r:system_file:s0"` (debugfs stores it NUL-terminated like stock: verify the 26-byte length). Sort package lists before emitting.
- [ ] **Step 4:** `bats tests/test_img_edit.bats` → PASS.
- [ ] **Step 5:** Commit `feat(rom): debugfs-based image editor`.

### Task 15: `build.sh` (OTA in, images and flash zip out)

**Files:**
- Create: `rom/build.sh`, `rom/config/ota-allowlist.txt`, `rom/tests/test_build.bats`

**Interfaces:**
- Consumes: Tasks 1-4 and 14.
- Produces: `build.sh --ota <file> --upto <batch> [--glass <apk>] [--vendor-no-install-recovery] --out out/` → `out/system.img vendor.img product.img` (raw, full partition size), `out/glass-os-<batch>.zip` (Task 16 layout), `out/SHA256SUMS`, `out/build-info.txt` (OTA sha, batch, removed list, Glass versionName + sha, tool versions).

- [ ] **Step 1:** Tests: `rejects_unknown_ota` (random 1 MB file → exit 2, `out/` empty), `lint_failure_stops_build` (tsv with minerva api → exit 1 before any image is written), `batch1_output_has_no_tutorial`, `reproducible` (two `--upto 1` builds → identical `SHA256SUMS`), `never_emits_bootloader_parts` (zip lists only system/vendor/product images).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement the pipeline: sha check → `7z x` OTA (payload names from `work/`) → `brotli -d` → `sdat2img.py` → aapt2 manifests (cache in `work/`) → lint (`--upto`) → `img_edit.py remove` → optional Glass add (refuse if free blocks after removal < APK blocks + 64) → `truncate -s <partition size>` check → zip. Use `set -euo pipefail`, `export TZ=UTC SOURCE_DATE_EPOCH=1230768000`, `zip -X` with sorted entries and fixed mtimes (`touch -d 1230768000`).
- [ ] **Step 4:** `bats tests/test_build.bats` → PASS. Also `e2fsck -fn out/system.img` clean.
- [ ] **Step 5:** Commit `feat(rom): deterministic build.sh`.

### Task 16: TWRP flash zip (written before device work; tested on the Mac)

**Files:**
- Create: `rom/tools/flashzip/update-binary`, `rom/tools/flashzip/updater-script` (`#MAGISK`-style dummy), `rom/tests/test_flashzip.bats`

**Interfaces:**
- Produces: zip layout `META-INF/com/google/android/{update-binary,updater-script}`, `images/<part>.img`, `images/SHA256SUMS`, `expect.prop` (device=karat, incremental=0032548774788). update-binary env overrides `BLOCKDIR` and `GETPROP` so tests run on the Mac against loop files.

- [ ] **Step 1:** Tests with fake block files in `$BATS_TMPDIR/mapper/`: `writes_and_verifies`, `refuses_unknown_partition` (an `images/lk.img` → abort, nothing written), `refuses_size_mismatch`, `refuses_wrong_device`, `refuses_when_mounted` (fake `/proc/mounts` lists the target).
- [ ] **Step 2:** FAIL. **Step 3:** Implement: allowlist {system,vendor,product}; for each, if `/dev/block/mapper/<p>` is missing run `lptools map <p>` or `dmctl create` per TWRP capability found in D10, compare `blockdev --getsize64` with image size, `dd bs=4M conv=fsync`, read back with `head -c <size> | sha256sum`, abort on mismatch. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(rom): TWRP flash zip with read-back verification`.


### Task 17: Verity off with an unmodified system (Gate G3)

- [ ] **Step 1 (user OK; verity off decided, spec section 8):** On the stick: `su -c 'cp /data/local/tmp/boot-current.img …'` from the D3 dump; `su -c 'cd /data/adb/magisk && KEEPVERITY=false KEEPFORCEENCRYPT=true sh boot_patch.sh /data/local/tmp/boot-current.img'` → `new-boot.img`. Pull it; record sha.
- [ ] **Step 2:** `su -c dd if=/data/local/tmp/new-boot.img of=/dev/block/by-name/boot bs=4M conv=fsync`, re-read sha equals. Reboot.
- [ ] **Step 3:** Verify: `sys.boot_completed=1`; `su -c dmctl table system` shows no `verity` target; `tools/smoke.sh` (Task 7) passes on stock system.
- [ ] **Rollback:** from Android or TWRP, `dd` `backup/…/boot.img` to `by-name/boot`.
- [ ] **Step 4: Gate G3.** If verity is still on, stop and switch to V-A (new task: `tools/rehash.sh` with `avbtool add_hashtree_footer --partition_size <stock> --salt 9dc2134d…f6f2 --hash_algorithm sha256 --do_not_generate_fec false` + `make_vbmeta_image`), which needs a fresh user decision.

### Task 18: First image change: one package (Gate G4)

- [ ] **Step 0:** Batch 1a has soaked in Glass Pro (Task 10).
- [ ] **Step 1:** `config/remove-candidates.tsv`: temporarily set batch 1 to `com.amazon.tmm.tutorial` only (move `storm.lightning.tutorial` to batch 1b). `./build.sh --ota input/… --upto 1 --out out/b1` → `out/b1/glass-os-1.zip`.
- [ ] **Step 2:** Mac-side proof: `debugfs -R 'ls /system/system_ext/priv-app' out/b1/system.img | grep -c tmm.tutorial` → `0`; `cmp -l work/system.img out/b1/system.img | wc -l` small (only touched blocks).
- [ ] **Step 3 (user OK):** `adb push out/b1/glass-os-1.zip /sdcard/`; `adb reboot recovery`; `adb shell twrp install /sdcard/glass-os-1.zip`; read its log: each partition `verified`. Reboot.
- [ ] **Step 4:** `tools/smoke.sh` → 0; `pm list packages | grep -c tmm.tutorial` → `0`; then `~/Documents/glass-launcher/scripts/e2e --stick` → pass (same failures as baseline at most). Run `tools/smoke.sh --manual` with the user (Alexa, Netflix, CEC, AirPlay, screensaver).
- [ ] **Rollback:** TWRP: `dd if=backup/…/system.img of=/dev/block/mapper/system` (or flash a zip built with `--upto 0`).
- [ ] **Step 5: Gate G4.** Commit `feat(rom): batch 1a removes tmm.tutorial`.

### Task 19: Removal batches 1b-8 (Gates G5.1-G5.8)

For each batch N in 1b, 2, 3, 4, 5, 6, 7, 8 (each already soaked in Glass Pro, Task 11), as a separate gate:
- [ ] **Step 1:** `python3 -I tools/lint_removals.py … --upto N` → 0 errors, no WARN (or each WARN explained in the batch commit body).
- [ ] **Step 2:** `./build.sh --upto N --out out/bN`; flash via TWRP as in Task 18.
- [ ] **Step 3:** `smoke.sh` + `e2e --stick` + manual checklist; batch 4 (minerva, OTA, recommendations, crashmanager) and batch 5 (launcher, homestarter) also need a 24 h soak: `logcat -b crash -d` empty for KEEP packages next day, remote still bonded after an overnight sleep and a reboot.
- [ ] **Step 4:** Commit `feat(rom): batch N removes <short list>`. Update `research/package-classification.md` (regenerate) with the date verified.
- **Rollback:** flash the previous batch's zip (`out/b<N-1>`).

### Task 20: Bake Glass (Gate G6)

- [ ] **Step 1:** `scripts/build release` in glass-launcher (or the CI artifact), copy the APK path. `./build.sh --upto 5 --glass <apk> --out out/glass` → system has `/system/priv-app/GlassLauncher/GlassLauncher.apk` and the allowlist XML (verify with debugfs `stat` + `cat`).
- [ ] **Step 2 (user OK):** Before flashing, switch Glass Pro to companion mode (`glasspro/build.sh --mode companion`, install) so only the baked Glass copy and the image's removals are active after reboot. Flash; reboot.
- [ ] **Step 3:** `dumpsys package dev.glasslauncher | grep codePath` → `/data/app/…` if an update exists over the system copy, else `/system/priv-app/GlassLauncher`; `privateFlags` include `PRIVILEGED`. HOME resolves to Glass. `smoke.sh` + `e2e --stick` pass.
- [ ] **Rollback:** flash `out/b5` zip and re-install the full Glass Pro zip.
- [ ] **Step 4:** Commit `feat(rom): bake Glass as privileged home`.

### Task 21: Factory-reset test (Gate G7)

Runs only after batch 4 is in the image (OTA updater packages deleted), backups proven (G2), and with the user's OK (decision 5).
- [ ] **Step 1:** Fresh backup of `boot` and Mac copy of `/data/adb` (`adb exec-out su -c 'tar -C /data/adb -cf - .' > backup/<date>/data-adb.tar`, sha both sides).
- [ ] **Step 2:** Unplug Ethernet/turn off the router's Wi-Fi for the stick or keep it offline in OOBE until Step 4. Reset from Fire Settings.
- [ ] **Step 3:** Expected: OOBE completes; Magisk app present? If not, re-flash the Magisk-patched boot (G3 file) from TWRP; restore `/data/adb` from the tar.
- [ ] **Step 4:** Go online; `getprop ro.boot.verifiedbootstate`, `su -c id`, `lk`/`lk_real` sha unchanged (D6); HOME = Glass; smoke.
- [ ] **Step 5:** Record the exact recovery sequence in docs (troubleshooting). Commit `docs(rom): factory reset behaviour`.

### Task 22: Public build script release

- [ ] **Step 1:** `rom/README.md`: what it does, the supported OTA sha, prerequisites (brew list, aapt2), the three recovery paths, "you need your own OTA", no warranty.
- [ ] **Step 2:** Leak check: `git ls-files | xargs file | grep -Ei 'android|ext4|data' ` → nothing binary; `grep -rE 'G072''JM|/Users''/' $(git ls-files)` → nothing.
- [ ] **Step 3:** Fresh clone test: clone to a temp dir, `./build.sh --ota <path> --upto 5 --out /tmp/o` → `SHA256SUMS` identical to `out/b5/SHA256SUMS`.
- [ ] **Step 4:** Commit `docs(rom): README for the Glass OS build script`; publish only with the user's OK.


---

## Phase C: Docs, account center, kernel

### Task 23: Docs site

Implement `rom/docs/docs-site-plan.md` (its own task list). Tier pages link Glass Pro = tier 2, Glass OS = tier 3. Starts after Task 13 so tier-2 install docs describe a real release.

### Task 24: Account center check (option B in `research/account-center.md`)

- [ ] **Step 1 (read-only, stick lock):** pull the installed Prime Video APK (`pm path com.amazon.firebat` or the avod package), `aapt2 dump xmltree` + dex strings for isolation/child-app markers listed in the research file. Summary only, no code.
- [ ] **Step 2:** Verdict in `research/account-center.md`; if isolation is declared, ask the user before a 3-6 day prototype (option C). Otherwise close as "profiles only".

### Task 25: Kernel and hardware tuning (later phase)

- [ ] **Step 1:** D1 compares `/proc/cmdline` with the boot header cmdline (`unpack_bootimg`); note what kaeru overrides.
- [ ] **Step 2:** Add governor, I/O scheduler, read-ahead, GPU devfreq and zram algorithm knobs to Glass Pro `service.sh` behind a config file, one knob per commit, each measured with `scripts/perf-gate` (no regression) and `scripts/vitals`.
- [ ] **Step 3:** Custom kernel only if Amazon's karat GPL source is found and the user asks.


## Device-side read-only checks needed later (summary)

D1 boot state + cmdline · D2 by-name/mapper layout, super size, lpdump · D3 current boot sha and Magisk KEEPVERITY · D4 dm-verity tables · D5 recovery = TWRP? install-recovery active? · D6 lk/lk_real hashes · D7 Glass install location, signature, current allowlist · D8 disabled/system package lists, HOME resolution · D9 SELinux, privapp enforce · D10 TWRP mapper + tools · D11 device access (software first) · D12 `/data/app` shadows of REMOVE packages · D13 copy of the current Glass Magisk setup.

## Manager review (2026-10-10)

The plan is sound: writes are limited to system/vendor/product (and boot via Magisk only), a tested backup and restore comes before any write, removals start with a single package, and the build script is deterministic and ships no Amazon files. Changes to make before execution:

1. Move `com.amazon.whisperjoin.middleware.v2.np` from batch 2 to INVESTIGATE. WhisperJoin is part of Amazon's device-provisioning and pairing stack, and the remote's pairing and auto-pair are both fragile on this stick (P37).
2. Move `com.amazon.spotify.mediabrowserservice` to INVESTIGATE. The user uses Spotify (Top Shelf / Now Playing), and it may back Alexa's Spotify playback.
3. Renumber the tasks so their numbers match execution order (currently 6 and 9 run before 8).
4. The answers to Open Questions 1–6 decide the INVESTIGATE rows and Gate G1. Do not start Phase B without them.

Applied 2026-10-10: items 1-2 (both packages now INVESTIGATE; lint re-run: 30 removed, 0 errors), item 3 (tasks renumbered into execution order, gate ids unchanged), item 4 (decisions recorded in spec section 8).
