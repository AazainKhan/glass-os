#!/usr/bin/env bash
# Builds the Glass Pro Magisk module zip.
#   tools/glasspro/build.sh --upto N --glass <apk> [--mode full|companion] --out <dir> [options]
# full      Glass as a privileged system app + the systemless debloat of every batch up to N.
# companion no debloat and no Glass priv-app (for Glass OS, where those are in the image); --upto not needed.
# Options (defaults come from the Glass TV Launcher checkout in $GLASS_REPO, default ~/Documents/glass-launcher):
#   --extra-from <RootFeatures.kt>  EXTRA_PRIVILEGED source for Glass's allowlist
#   --keymap <glass-keymap>         static ARM binary built from tools/keymap/glass-keymap.c
#   --keepalive <script>            the reworked remote keepalive; goes into the module's keepalive/ slot
#   --version <x.y.z>               module version (default from tools/glasspro/VERSION)
#   --apps-dir <dir>                use already-fetched bundled apps (default: run tools/fetch_apps.sh)
#   --manifests <json> --libs <txt> --remove-tsv <tsv>   inputs for the debloat list and its lint
# Output: <out>/glass-pro-<version>-b<N>.zip (or -companion), <out>/glass-pro.zip (copy), <out>/glass-pro.SHA256.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$ROOT/tools/glasspro"
# shellcheck source=../env.sh
. "$ROOT/tools/env.sh"
GLASS_REPO="${GLASS_REPO:-$HOME/Documents/glass-launcher}"

MODE=full; UPTO=""; GLASS=""; OUT=""; VERSION="$(cat "$HERE/VERSION")"
EXTRA_FROM="$GLASS_REPO/app/src/main/java/dev/glasslauncher/system/RootFeatures.kt"
KEYMAP="$GLASS_REPO/tools/keymap/glass-keymap"; KEEPALIVE=""; APPS_DIR=""
MANIFESTS="$ROOT/work/manifests.json"; LIBS="$ROOT/work/libs_features.txt"; REMOVE_TSV="$ROOT/config/remove-candidates.tsv"
die() { echo "glasspro/build: $*" >&2; exit 1; }
while [ $# -gt 0 ]; do
  case "$1" in
    --upto) UPTO="$2"; shift 2 ;;       --glass) GLASS="$2"; shift 2 ;;      --mode) MODE="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;         --extra-from) EXTRA_FROM="$2"; shift 2 ;;
    --keymap) KEYMAP="$2"; shift 2 ;;   --keepalive) KEEPALIVE="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;; --apps-dir) APPS_DIR="$2"; shift 2 ;;
    --manifests) MANIFESTS="$2"; shift 2 ;; --libs) LIBS="$2"; shift 2 ;; --remove-tsv) REMOVE_TSV="$2"; shift 2 ;;
    *) die "unknown option $1" ;;
  esac
done
[ -n "$OUT" ] || die "--out is required"
case "$MODE" in full|companion) ;; *) die "--mode must be full or companion" ;; esac
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must be x.y.z"
if [ "$MODE" = full ]; then
  [ -n "$UPTO" ] || die "--upto is required in full mode"
  [ -f "$GLASS" ] || die "--glass <apk> is required in full mode (not found: ${GLASS:-unset})"
  [ -f "$MANIFESTS" ] && [ -f "$LIBS" ] || die "debloat inputs missing ($MANIFESTS, $LIBS)"
fi
[ -f "$KEYMAP" ] || die "glass-keymap not found: $KEYMAP"
[ "$(head -c 4 "$KEYMAP" | od -An -c | tr -d ' ')" = '177ELF' ] || die "glass-keymap is not an ELF file"
[ -z "$KEEPALIVE" ] || [ -f "$KEEPALIVE" ] || die "keepalive script not found: $KEEPALIVE"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
S="$tmp/stage"; mkdir -p "$S/META-INF/com/google/android" "$S/system/etc/permissions" "$S/system/vendor/etc"

# Module scripts and fixed files.
cp "$HERE/update-binary" "$S/META-INF/com/google/android/update-binary"
printf '#MAGISK\n' > "$S/META-INF/com/google/android/updater-script"
for f in customize.sh post-fs-data.sh service.sh uninstall.sh README.md; do cp "$HERE/$f" "$S/$f"; done
cp "$ROOT/THIRD_PARTY.md" "$S/THIRD_PARTY.md"
cp "$HERE/files/fstab.enableswap" "$S/system/vendor/etc/fstab.enableswap"
cp "$ROOT/config/fireos-builds.txt" "$S/fireos-builds.txt"
cp "$KEYMAP" "$S/glass-keymap"

vc=$(( $(echo "$VERSION" | cut -d. -f1) * 10000 + $(echo "$VERSION" | cut -d. -f2) * 100 + $(echo "$VERSION" | cut -d. -f3) ))
cat > "$S/module.prop" <<PROP
id=glass-pro
name=Glass Pro
version=v$VERSION
versionCode=$vc
author=Glass TV Launcher
description=Glass TV Launcher as a privileged home app, memory tuning, remote button mapping, a systemless debloat and a bundled store and browser for the Fire TV Stick 4K 2nd Gen.
PROP

# Bundled apps (Droid-ify, TV Bro) and their allowlist.
if [ -z "$APPS_DIR" ]; then APPS_DIR="$tmp/apps"; "$ROOT/tools/fetch_apps.sh" "$APPS_DIR"; fi
cp -R "$APPS_DIR"/. "$S"/

# Glass and the debloat (full mode only).
if [ "$MODE" = full ]; then
  mkdir -p "$S/system/priv-app/GlassLauncher"
  cp "$GLASS" "$S/system/priv-app/GlassLauncher/GlassLauncher.apk"
  pkg="$("$AAPT2" dump packagename "$GLASS")"
  python3 -I "$ROOT/tools/privapp_xml.py" "$GLASS" --extra-from "$EXTRA_FROM" > "$S/system/etc/permissions/privapp-permissions-$pkg.xml" \
    || die "Glass allowlist generation failed"
  python3 -I "$ROOT/tools/lint_removals.py" "$MANIFESTS" "$LIBS" "$REMOVE_TSV" --upto "$UPTO" > "$tmp/lint.txt" \
    || { cat "$tmp/lint.txt" >&2; die "removal lint failed for --upto $UPTO"; }
  python3 -I "$ROOT/tools/replace_list.py" "$MANIFESTS" "$REMOVE_TSV" --upto "$UPTO" --format magisk > "$tmp/replace.txt"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    mkdir -p "$S/$d"; : > "$S/$d/.replace"
  done < "$tmp/replace.txt"
fi

# Keepalive slot (see service.sh section 4).
if [ -n "$KEEPALIVE" ]; then mkdir -p "$S/keepalive"; cp "$KEEPALIVE" "$S/keepalive/service.sh"; fi

# Provenance, deterministic (no dates, no paths).
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
{
  echo "module: glass-pro v$VERSION ($MODE)"
  if [ "$MODE" = full ]; then
    echo "batches: up to $UPTO ($(wc -l < "$tmp/replace.txt" | tr -d ' ') package dirs replaced)"
    echo "glass.apk sha256: $(sha "$GLASS")"
    echo "glass.apk signer: $("$APKSIGNER" verify --print-certs "$GLASS" 2>/dev/null | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -1)"
  fi
  echo "glass-keymap sha256: $(sha "$KEYMAP")"
  if [ -n "$KEEPALIVE" ]; then echo "keepalive slot: $(sha "$KEEPALIVE")"; else echo "keepalive slot: empty (legacy script from backup/ is used if present)"; fi
  grep -v '^#' "$ROOT/config/bundled-apps.tsv" | cut -f1,3,4 | tr '\t' ' ' | awk '{print "bundled " $1 " " $3 " sha256 " $2}'
} > "$S/build-info.txt"

# Zip.
mkdir -p "$OUT"
if [ "$MODE" = full ]; then name="glass-pro-$VERSION-b$UPTO.zip"; else name="glass-pro-$VERSION-companion.zip"; fi
python3 -I "$HERE/mkzip.py" "$S" "$OUT/$name"
cp "$OUT/$name" "$OUT/glass-pro.zip"
( cd "$OUT" && shasum -a 256 "$name" glass-pro.zip > glass-pro.SHA256 )
echo "glasspro/build: $OUT/$name"
