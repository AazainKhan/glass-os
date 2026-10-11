#!/usr/bin/env bats
# Offline: AVB_URL points at a local file holding base64 text, like the googlesource ?format=TEXT body.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  printf '#!/usr/bin/env python3\nprint("fake avbtool")\n' > "$BATS_TEST_TMPDIR/src.py"
  base64 < "$BATS_TEST_TMPDIR/src.py" > "$BATS_TEST_TMPDIR/src.b64"
  export AVB_URL="file://$BATS_TEST_TMPDIR/src.b64"
  export TOOLS_BIN="$BATS_TEST_TMPDIR/bin"
}

@test "wrong sha exits 1 and leaves no avbtool.py" {
  AVB_SHA256=0000000000000000000000000000000000000000000000000000000000000000 run "$ROOT/tools/fetch-tools.sh"
  [ "$status" -eq 1 ]
  [ ! -e "$TOOLS_BIN/avbtool.py" ]
}

@test "matching sha installs an executable avbtool.py" {
  AVB_SHA256="$(shasum -a 256 "$BATS_TEST_TMPDIR/src.py" | cut -d' ' -f1)" run "$ROOT/tools/fetch-tools.sh"
  [ "$status" -eq 0 ]
  [ -x "$TOOLS_BIN/avbtool.py" ]
}
