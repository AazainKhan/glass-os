#!/usr/bin/env bats
# Offline: the pinned URLs are file:// URLs to APKs built and signed in setup_file with a throwaway key.

setup_file() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; . "$ROOT/tools/env.sh"
  D="$BATS_FILE_TMPDIR"
  jar="$(ls "$HOME"/Library/Android/sdk/platforms/*/android.jar | tail -1)"
  keytool -genkeypair -keystore "$D/k.jks" -storepass testpass -keypass testpass -alias t -keyalg RSA -keysize 2048 \
    -validity 100 -dname "CN=test" >/dev/null 2>&1
  for spec in "privapp:com.example.privapp:android.permission.INSTALL_PACKAGES,android.permission.UPDATE_PACKAGES_WITHOUT_USER_ACTION,android.permission.INTERNET" \
              "plainapp:com.example.plainapp:android.permission.INTERNET"; do
    IFS=: read -r n pkg perms <<<"$spec"
    uses=""; IFS=, read -ra arr <<<"$perms"; for p in "${arr[@]}"; do uses="$uses<uses-permission android:name=\"$p\"/>"; done
    printf '<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="%s">%s<application/></manifest>' "$pkg" "$uses" > "$D/$n.xml"
    "$AAPT2" link -o "$D/$n.unsigned.apk" -I "$jar" --manifest "$D/$n.xml"
    "$APKSIGNER" sign --ks "$D/k.jks" --ks-pass pass:testpass --key-pass pass:testpass --out "$D/$n.apk" "$D/$n.unsigned.apk" 2>/dev/null
  done
  printf 'android.permission.INSTALL_PACKAGES\nandroid.permission.INTERNET\n' > "$D/declared.txt"
  signer="$("$APKSIGNER" verify --print-certs "$D/privapp.apk" 2>/dev/null | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -1)"
  echo "$signer" > "$D/signer"
}

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"; D="$BATS_FILE_TMPDIR"; signer="$(cat "$D/signer")"
  export DECLARED_PERMS="$D/declared.txt" BUNDLED_APPS_TSV="$BATS_TEST_TMPDIR/apps.tsv" OUT="$BATS_TEST_TMPDIR/out"
  sp="$(shasum -a 256 "$D/privapp.apk" | cut -d' ' -f1)"; sn="$(shasum -a 256 "$D/plainapp.apk" | cut -d' ' -f1)"
  write_tsv "$sp" "$sn"
}

write_tsv() {
  printf '# header\nPrivApp\tfile://%s/privapp.apk\t%s\t1\tsystem/priv-app/PrivApp\tyes\t%s\tcom.example.privapp\nPlainApp\tfile://%s/plainapp.apk\t%s\t1\tsystem/app/PlainApp\tno\t%s\tcom.example.plainapp\n' \
    "$D" "$1" "$signer" "$D" "$2" "$signer" > "$BUNDLED_APPS_TSV"
}

@test "wrong_sha_fails_and_leaves_nothing" {
  write_tsv "$sp" 0000000000000000000000000000000000000000000000000000000000000000
  run "$ROOT/tools/fetch_apps.sh" "$OUT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"sha256 mismatch"* ]]
  [ ! -e "$OUT" ]
}

@test "priv_apk_gets_xml" {
  run "$ROOT/tools/fetch_apps.sh" "$OUT"
  [ "$status" -eq 0 ]
  x="$OUT/system/etc/permissions/privapp-permissions-com.example.privapp.xml"
  [ -f "$x" ]
  grep -q 'android.permission.INSTALL_PACKAGES' "$x"
  # undeclared (Android 12+) name is dropped, requested declared ones stay
  ! grep -q UPDATE_PACKAGES_WITHOUT_USER_ACTION "$x"
  grep -q 'android.permission.INTERNET' "$x"
}

@test "non_priv_apk_has_no_xml" {
  run "$ROOT/tools/fetch_apps.sh" "$OUT"
  [ "$status" -eq 0 ]
  [ -f "$OUT/system/app/PlainApp/PlainApp.apk" ]
  [ ! -e "$OUT/system/etc/permissions/privapp-permissions-com.example.plainapp.xml" ]
}

@test "apk_not_resigned" {
  run "$ROOT/tools/fetch_apps.sh" "$OUT"
  [ "$status" -eq 0 ]
  . "$ROOT/tools/env.sh"
  cmp "$D/privapp.apk" "$OUT/system/priv-app/PrivApp/PrivApp.apk"
  got="$("$APKSIGNER" verify --print-certs "$OUT/system/app/PlainApp/PlainApp.apk" 2>/dev/null | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -1)"
  [ "$got" = "$signer" ]
}

@test "wrong_signer_pin_fails_and_leaves_nothing" {
  sed -i.bak "s/$signer/1111111111111111111111111111111111111111111111111111111111111111/" "$BUNDLED_APPS_TSV"
  run "$ROOT/tools/fetch_apps.sh" "$OUT"
  [ "$status" -eq 1 ]
  [[ "$output" == *"signer certificate mismatch"* ]]
  [ ! -e "$OUT" ]
}

@test "modes_and_layout_are_stable" {
  "$ROOT/tools/fetch_apps.sh" "$OUT"
  [ "$(stat -f %Lp "$OUT/system/priv-app/PrivApp")" = 755 ]
  [ "$(stat -f %Lp "$OUT/system/priv-app/PrivApp/PrivApp.apk")" = 644 ]
}

@test "real_tsv_is_well_formed" {
  run python3 -I - "$ROOT/config/bundled-apps.tsv" <<'PY'
import re, sys
rows = [l.rstrip('\n').split('\t') for l in open(sys.argv[1]) if l.strip() and not l.startswith('#')]
assert len(rows) == 2, rows
for r in rows:
    assert len(r) == 8, r
    assert r[1].startswith('https://github.com/'), r
    assert re.fullmatch(r'[0-9a-f]{64}', r[2]) and re.fullmatch(r'[0-9a-f]{64}', r[6]), r
    assert r[5] in ('yes', 'no')
assert {r[0] for r in rows} == {'Droidify', 'TVBro'}
assert 'geckoExcluded' in rows[1][1]
PY
  [ "$status" -eq 0 ]
}
