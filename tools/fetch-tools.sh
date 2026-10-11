#!/usr/bin/env bash
# Fetches pinned build tools into tools/bin/. Currently: avbtool.py from AOSP external/avb.
# android11-release is unusable (its avbtool.py is a symlink stub), so a main commit is pinned.
# Overrides (tests only): AVB_URL, AVB_SHA256, TOOLS_BIN.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AVB_COMMIT=761178607206f4cb2af79ed9eec52d8cbd814adb
AVB_SHA256="${AVB_SHA256:-e5a664a38db623da00f080219bc0ee60a640a9dc4a872803616fae4938ac749b}"
AVB_URL="${AVB_URL:-https://android.googlesource.com/platform/external/avb/+/$AVB_COMMIT/avbtool.py?format=TEXT}"
BIN="${TOOLS_BIN:-$ROOT/tools/bin}"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$BIN"
curl -fsSL "$AVB_URL" | base64 -d > "$tmp/avbtool.py"
got="$(shasum -a 256 "$tmp/avbtool.py" | cut -d' ' -f1)"
if [ "$got" != "$AVB_SHA256" ]; then
  echo "fetch-tools: avbtool.py sha256 mismatch (got $got, want $AVB_SHA256)" >&2
  exit 1
fi
install -m 755 "$tmp/avbtool.py" "$BIN/avbtool.py"
echo "fetch-tools: avbtool.py ok ($AVB_COMMIT)"
