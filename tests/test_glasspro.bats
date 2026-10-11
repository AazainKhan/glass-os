#!/usr/bin/env bats
# Builds Glass Pro from fixtures (no Amazon data, no device) and checks the zip and its scripts.

setup_file() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; . "$ROOT/tools/env.sh"
  D="$BATS_FILE_TMPDIR"; FIX="$ROOT/tests/fixtures"
  jar="$(ls "$HOME"/Library/Android/sdk/platforms/*/android.jar | tail -1)"
  printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="dev.glasslauncher"><uses-permission android:name="android.permission.INTERNET"/><uses-permission android:name="android.permission.WRITE_SECURE_SETTINGS"/><application/></manifest>' > "$D/m.xml"
  "$AAPT2" link -o "$D/glass.apk" -I "$jar" --manifest "$D/m.xml"
  printf '\177ELF fake keymap for tests' > "$D/glass-keymap"
  printf 'object X {\n  private val EXTRA_PRIVILEGED = listOf(\n    "com.android.providers.tv.permission.ACCESS_ALL_EPG_DATA",\n  )\n}\n' > "$D/RootFeatures.kt"
  mkdir -p "$D/apps/system/priv-app/Droidify" "$D/apps/system/app/TVBro" "$D/apps/system/etc/permissions"
  echo apk1 > "$D/apps/system/priv-app/Droidify/Droidify.apk"; echo apk2 > "$D/apps/system/app/TVBro/TVBro.apk"
  echo xml > "$D/apps/system/etc/permissions/privapp-permissions-com.looker.droidify.xml"
  printf '#!/bin/sh\necho new keepalive\n' > "$D/keepalive.sh"
  for mode in full companion; do
    "$ROOT/tools/glasspro/build.sh" --mode "$mode" --upto 1b --glass "$D/glass.apk" --out "$D/out-$mode" \
      --extra-from "$D/RootFeatures.kt" --keymap "$D/glass-keymap" --apps-dir "$D/apps" \
      --manifests "$FIX/manifests.json" --libs "$FIX/libs_features.txt" --remove-tsv "$FIX/remove.tsv" >/dev/null
  done
  "$ROOT/tools/glasspro/build.sh" --upto 1b --glass "$D/glass.apk" --out "$D/out-ka" --keepalive "$D/keepalive.sh" \
      --extra-from "$D/RootFeatures.kt" --keymap "$D/glass-keymap" --apps-dir "$D/apps" \
      --manifests "$FIX/manifests.json" --libs "$FIX/libs_features.txt" --remove-tsv "$FIX/remove.tsv" >/dev/null
  mkdir -p "$D/x-full" "$D/x-companion"
  unzip -q "$D"/out-full/glass-pro-0.1.0-b1b.zip -d "$D/x-full"
  unzip -q "$D"/out-companion/glass-pro-0.1.0-companion.zip -d "$D/x-companion"
  # fake getprop
  cat > "$D/getprop" <<'GP'
#!/bin/sh
case "$1" in
  ro.product.device) echo "${FAKE_DEVICE:-karat}" ;;
  ro.build.fingerprint) echo "${FAKE_FP:-Amazon/karat/karat:11/RS8182.3811N/0032548774788:user/amz-p,release-keys}" ;;
esac
GP
  chmod +x "$D/getprop"
}

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; D="$BATS_FILE_TMPDIR"; FIX="$ROOT/tests/fixtures"
  ZIP="$D/out-full/glass-pro-0.1.0-b1b.zip"
}

# Runs the module's customize.sh the way Magisk sources it, against a scratch /data/adb.
customize() {  # $1 = extracted module dir to install from
  MODPATH="$BATS_TEST_TMPDIR/modpath"; ADB_DATA="$BATS_TEST_TMPDIR/adb"
  rm -rf "$MODPATH"; cp -R "$1" "$MODPATH"
  mkdir -p "$ADB_DATA/modules" "$ADB_DATA/service.d"
  export MODPATH ADB_DATA GETPROP="$D/getprop"
  KL_SRC="${KL_SRC:-$BATS_TEST_TMPDIR/stock.kl}"; export KL_SRC
  printf 'key 744   APP_1\nkey 745   APP_2\nkey 746   APP_3\nkey 747   APP_4\nkey 748   RECENTS\nkey 249   BUTTON_16\nkey 185   F20\nkey 184   F19\nkey 103   DPAD_UP\n' > "$BATS_TEST_TMPDIR/stock.kl"
  sh -c 'abort() { echo "ABORT: $*" >&2; exit 1; }; ui_print() { echo "$*"; }; . "$MODPATH/customize.sh"'
}

@test "zip_has_replace_markers_for_batch" {
  unzip -Z1 "$ZIP" | grep '/\.replace$' | sed 's#/\.replace$##' | sort > "$BATS_TEST_TMPDIR/got"
  python3 -I "$ROOT/tools/replace_list.py" "$FIX/manifests.json" "$FIX/remove.tsv" --upto 1b --format magisk | sort > "$BATS_TEST_TMPDIR/want"
  [ -s "$BATS_TEST_TMPDIR/want" ]
  diff "$BATS_TEST_TMPDIR/got" "$BATS_TEST_TMPDIR/want"
  # nothing else lives inside those directories
  while read -r d; do [ "$(unzip -Z1 "$ZIP" | grep -c "^$d/")" = 1 ]; done < "$BATS_TEST_TMPDIR/want"
}

@test "zip_structure_is_a_magisk_module" {
  unzip -Z1 "$ZIP" > "$BATS_TEST_TMPDIR/list"
  for f in META-INF/com/google/android/update-binary META-INF/com/google/android/updater-script module.prop customize.sh \
           service.sh post-fs-data.sh uninstall.sh glass-keymap build-info.txt THIRD_PARTY.md system/vendor/etc/fstab.enableswap \
           system/priv-app/GlassLauncher/GlassLauncher.apk system/etc/permissions/privapp-permissions-dev.glasslauncher.xml \
           system/priv-app/Droidify/Droidify.apk system/app/TVBro/TVBro.apk; do
    grep -qx "$f" "$BATS_TEST_TMPDIR/list" || { echo "missing $f"; return 1; }
  done
  [ "$(unzip -p "$ZIP" META-INF/com/google/android/updater-script)" = "#MAGISK" ]
  unzip -p "$ZIP" module.prop | grep -qx 'id=glass-pro'
  # no key layout in the zip (it is generated on the stick), and only the three expected APKs
  ! grep -q 'keylayout' "$BATS_TEST_TMPDIR/list"
  [ "$(grep -c '\.apk$' "$BATS_TEST_TMPDIR/list")" = 3 ]
  unzip -p "$ZIP" system/etc/permissions/privapp-permissions-dev.glasslauncher.xml | grep -q 'ACCESS_ALL_EPG_DATA'
  unzip -p "$ZIP" system/etc/permissions/privapp-permissions-dev.glasslauncher.xml | grep -q 'WRITE_SECURE_SETTINGS'
}

@test "scripts_pass_sh_syntax_check" {
  for f in customize.sh service.sh post-fs-data.sh uninstall.sh META-INF/com/google/android/update-binary; do
    unzip -p "$ZIP" "$f" > "$BATS_TEST_TMPDIR/s.sh"; sh -n "$BATS_TEST_TMPDIR/s.sh"
  done
}

@test "companion_has_no_replace_and_no_glass" {
  l="$(unzip -Z1 "$D/out-companion/glass-pro-0.1.0-companion.zip")"
  ! grep -q '\.replace' <<<"$l"
  ! grep -qi 'glasslauncher' <<<"$l"
  grep -q 'service.sh' <<<"$l"
  grep -q 'Droidify.apk' <<<"$l"
}

@test "customize_marks_old_modules_for_removal" {
  mkdir -p "$BATS_TEST_TMPDIR/adb/modules/glass-system" "$BATS_TEST_TMPDIR/adb/modules/glass-tuning" "$BATS_TEST_TMPDIR/adb/modules/glass-remote-keys" "$BATS_TEST_TMPDIR/adb/modules/hosts"
  run customize "$D/x-full"
  [ "$status" -eq 0 ]
  for m in glass-system glass-tuning glass-remote-keys; do [ -e "$BATS_TEST_TMPDIR/adb/modules/$m/remove" ]; done
  [ ! -e "$BATS_TEST_TMPDIR/adb/modules/hosts/remove" ]
}

@test "customize_moves_service_d_scripts" {
  mkdir -p "$BATS_TEST_TMPDIR/adb/service.d"
  echo one > "$BATS_TEST_TMPDIR/adb/service.d/start-launcher.sh"; echo two > "$BATS_TEST_TMPDIR/adb/service.d/glass-remote-keepalive.sh"
  echo keep > "$BATS_TEST_TMPDIR/adb/service.d/other.sh"
  run customize "$D/x-full"
  [ "$status" -eq 0 ]
  [ ! -e "$BATS_TEST_TMPDIR/adb/service.d/start-launcher.sh" ]
  [ ! -e "$BATS_TEST_TMPDIR/adb/service.d/glass-remote-keepalive.sh" ]
  [ "$(cat "$BATS_TEST_TMPDIR/modpath/backup/start-launcher.sh")" = one ]
  [ "$(cat "$BATS_TEST_TMPDIR/modpath/backup/glass-remote-keepalive.sh")" = two ]
  [ -e "$BATS_TEST_TMPDIR/adb/service.d/other.sh" ]
}

@test "customize_refuses_wrong_device" {
  mkdir -p "$BATS_TEST_TMPDIR/adb/modules/glass-system" "$BATS_TEST_TMPDIR/adb/service.d"
  echo one > "$BATS_TEST_TMPDIR/adb/service.d/start-launcher.sh"
  FAKE_DEVICE=mantis run customize "$D/x-full"
  [ "$status" -eq 1 ]
  [[ "$output" == *"ABORT"*"karat"* ]]
  # nothing was touched
  [ ! -e "$BATS_TEST_TMPDIR/adb/modules/glass-system/remove" ]
  [ -e "$BATS_TEST_TMPDIR/adb/service.d/start-launcher.sh" ]
}

@test "customize_refuses_untested_build_unless_forced" {
  FAKE_FP="Amazon/karat/karat:11/OTHER/1:user/amz-p,release-keys" run customize "$D/x-full"
  [ "$status" -eq 1 ]
  [[ "$output" == *"tested list"* ]]
  mkdir -p "$BATS_TEST_TMPDIR/adb"; touch "$BATS_TEST_TMPDIR/adb/glass-pro-force"
  FAKE_FP="Amazon/karat/karat:11/OTHER/1:user/amz-p,release-keys" run customize "$D/x-full"
  [ "$status" -eq 0 ]
}

@test "customize_builds_keylayout_from_the_stock_file_idempotently" {
  run customize "$D/x-full"
  [ "$status" -eq 0 ]
  kl="$BATS_TEST_TMPDIR/modpath/system/usr/keylayout/Vendor_0171_Product_0427.kl"
  grep -q '^key 744 *BUTTON_9' "$kl"; grep -q '^key 748 *BUTTON_13' "$kl"; grep -q '^key 249 *SETTINGS' "$kl"
  ! grep -q '^key 18[45] ' "$kl"
  grep -q '^key 103 *DPAD_UP' "$kl"
  # feeding the already patched file back in gives the same file
  cp "$kl" "$BATS_TEST_TMPDIR/patched.kl"
  KL_SRC="$BATS_TEST_TMPDIR/patched.kl" run customize "$D/x-full"
  [ "$status" -eq 0 ]
  diff "$BATS_TEST_TMPDIR/patched.kl" "$kl"
}

@test "uninstall_restores_cached_processes_4" {
  MODDIR_COPY="$BATS_TEST_TMPDIR/mod"; cp -R "$D/x-full" "$MODDIR_COPY"
  ADB_DATA="$BATS_TEST_TMPDIR/adb" run sh "$MODDIR_COPY/uninstall.sh"
  [ "$status" -eq 0 ]
  r="$BATS_TEST_TMPDIR/adb/service.d/glass-pro-restore.sh"
  grep -q 'settings put global activity_manager_constants max_cached_processes=4' "$r"
  grep -q 'pm enable com.amazon.tv.launcher' "$r"
  sh -n "$r"
  # it deletes itself and its staging dir
  grep -q 'rm -rf .*glass-pro-restore' "$r"
}

@test "uninstall_calls_remote_keys_restore" {
  MODDIR_COPY="$BATS_TEST_TMPDIR/mod"; cp -R "$D/x-full" "$MODDIR_COPY"
  ADB_DATA="$BATS_TEST_TMPDIR/adb" sh "$MODDIR_COPY/uninstall.sh"
  r="$BATS_TEST_TMPDIR/adb/service.d/glass-pro-restore.sh"
  grep -q 'glass-keymap" remap "Fire TV Remote" 185 249' "$r"
  [ -x "$BATS_TEST_TMPDIR/adb/glass-pro-restore/glass-keymap" ]
}

@test "service_starts_home_once" {
  unzip -p "$ZIP" service.sh > "$BATS_TEST_TMPDIR/service.sh"
  grep -v '^[[:space:]]*#' "$BATS_TEST_TMPDIR/service.sh" > "$BATS_TEST_TMPDIR/code.sh"
  [ "$(grep -c 'am start' "$BATS_TEST_TMPDIR/code.sh")" = 1 ]
  grep 'am start' "$BATS_TEST_TMPDIR/code.sh" | grep -q -- '-a android.intent.action.MAIN -c android.intent.category.HOME'
  # no other launcher start anywhere in the module
  ! grep -rn 'am start' "$D/x-full" --include='*.sh' | grep -v 'service.sh' | grep .
}

@test "keepalive_slot_is_marked_and_does_not_reimplement" {
  unzip -p "$ZIP" service.sh > "$BATS_TEST_TMPDIR/service.sh"
  grep -q 'KEEPALIVE SLOT' "$BATS_TEST_TMPDIR/service.sh"
  grep -q 'keepalive/service.sh' "$BATS_TEST_TMPDIR/service.sh"
  grep -q 'backup/glass-remote-keepalive.sh' "$BATS_TEST_TMPDIR/service.sh"
  ! unzip -Z1 "$ZIP" | grep -q '^keepalive/'
  unzip -Z1 "$D/out-ka/glass-pro-0.1.0-b1b.zip" | grep -qx 'keepalive/service.sh'
  [ "$(unzip -p "$D/out-ka/glass-pro-0.1.0-b1b.zip" keepalive/service.sh)" = "$(cat "$D/keepalive.sh")" ]
}

@test "reproducible" {
  "$ROOT/tools/glasspro/build.sh" --upto 1b --glass "$D/glass.apk" --out "$D/out-again" \
      --extra-from "$D/RootFeatures.kt" --keymap "$D/glass-keymap" --apps-dir "$D/apps" \
      --manifests "$FIX/manifests.json" --libs "$FIX/libs_features.txt" --remove-tsv "$FIX/remove.tsv" >/dev/null
  [ "$(shasum -a 256 < "$ZIP")" = "$(shasum -a 256 < "$D/out-again/glass-pro-0.1.0-b1b.zip")" ]
  grep -q 'glass-pro-0.1.0-b1b.zip' "$D/out-again/glass-pro.SHA256"
  cmp "$D/out-again/glass-pro.zip" "$ZIP"
}

@test "lint_failure_blocks_the_build" {
  printf 'com.example.libowner\t1\tx\n' > "$BATS_TEST_TMPDIR/bad.tsv"
  run "$ROOT/tools/glasspro/build.sh" --upto 1 --glass "$D/glass.apk" --out "$BATS_TEST_TMPDIR/o" \
      --extra-from "$D/RootFeatures.kt" --keymap "$D/glass-keymap" --apps-dir "$D/apps" \
      --manifests "$FIX/manifests.json" --libs "$FIX/libs_features.txt" --remove-tsv "$BATS_TEST_TMPDIR/bad.tsv"
  [ "$status" -eq 1 ]
  [ ! -e "$BATS_TEST_TMPDIR/o/glass-pro.zip" ]
}

@test "zip_has_no_local_paths_or_device_serials" {
  rm -rf "$BATS_TEST_TMPDIR/all"; mkdir "$BATS_TEST_TMPDIR/all"; unzip -q "$ZIP" -d "$BATS_TEST_TMPDIR/all"
  ! grep -rIl -e '/Users/' -e 'G072''JM' "$BATS_TEST_TMPDIR/all" | grep .
}
