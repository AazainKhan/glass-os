#!/usr/bin/env bats
# smoke.sh against a fake adb. A poisoned `adb` first on PATH proves the real binary is never reached.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export FAKE_DIR="$BATS_TEST_TMPDIR/fake"; cp -R "$ROOT/tests/fixtures/smoke/good" "$FAKE_DIR"
  export ADB="$ROOT/tests/fixtures/fake-adb"
  mkdir -p "$BATS_TEST_TMPDIR/poison"
  printf '#!/bin/sh\necho "REAL ADB CALLED" >> "%s"\nexit 99\n' "$BATS_TEST_TMPDIR/real-adb-called" > "$BATS_TEST_TMPDIR/poison/adb"
  chmod +x "$BATS_TEST_TMPDIR/poison/adb"
  export PATH="$BATS_TEST_TMPDIR/poison:$PATH"
  # every KEEP package present; the batch-1a package absent
  awk -F'\t' '$2 == "KEEP" && $1 !~ /^#/ { print "package:" $1 }' "$ROOT/config/classification.tsv" > "$FAKE_DIR/packages"
}

teardown() {
  [ ! -e "$BATS_TEST_TMPDIR/real-adb-called" ]
  if grep -q UNEXPECTED "$FAKE_DIR/calls.log"; then return 1; fi
}

@test "passes_on_good_device" {
  run "$ROOT/tools/smoke.sh"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"PASS home"* ]]
  [[ "$output" == *"PASS removed_packages_gone (up to 1a)"* ]]
  [[ "$output" == *"all automatic checks passed"* ]]
}

@test "fails_on_vizzini_crash" {
  echo '10-10 12:01:00.000  900  900 E AndroidRuntime: Process: com.amazon.vizzini, PID: 4242' > "$FAKE_DIR/crash"
  echo 'java.lang.NullPointerException: windowTemplateId cannot be null' >> "$FAKE_DIR/crash"
  run "$ROOT/tools/smoke.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FAIL keep_crash"*"vizzini"* ]]
}

@test "fails_when_home_not_glass" {
  printf 'priority=0\ncom.amazon.tv.launcher/.ui.HomeActivity_vNext\n' > "$FAKE_DIR/home"
  run "$ROOT/tools/smoke.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FAIL home"* ]]
}

@test "fails_when_a_removed_package_is_still_installed" {
  echo 'package:com.amazon.tmm.tutorial' >> "$FAKE_DIR/packages"
  run "$ROOT/tools/smoke.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FAIL removed_packages_gone"*"com.amazon.tmm.tutorial"* ]]
}

@test "fails_when_a_keep_package_is_missing" {
  grep -v 'com.amazon.aria$' "$FAKE_DIR/packages" > "$FAKE_DIR/p2"; mv "$FAKE_DIR/p2" "$FAKE_DIR/packages"
  run "$ROOT/tools/smoke.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FAIL keep_packages_present"*"com.amazon.aria"* ]]
}

@test "fails_when_tuning_or_daemon_missing" {
  echo 'max_cached_processes=4' > "$FAKE_DIR/constants"; echo 'init' > "$FAKE_DIR/ps"
  run "$ROOT/tools/smoke.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FAIL cached_processes_12"* ]]
  [[ "$output" == *"FAIL remote_keys_daemon"* ]]
}

@test "unrelated_crash_and_android_word_do_not_fail" {
  echo 'E AndroidRuntime: Process: com.example.other, PID: 1 android.os.DeadObjectException' > "$FAKE_DIR/crash"
  run "$ROOT/tools/smoke.sh"
  [ "$status" -eq 0 ]
}

@test "manual_prints_the_spec_checklist" {
  run "$ROOT/tools/smoke.sh" --manual
  [ "$status" -eq 0 ]
  [[ "$output" == *"- [ ] Wi-Fi:"* ]]
  [[ "$output" == *"- [ ] Alexa voice:"* ]]
}
