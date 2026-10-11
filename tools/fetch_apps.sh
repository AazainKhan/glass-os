#!/usr/bin/env bash
# Downloads the bundled third-party APKs pinned in config/bundled-apps.tsv, verifies them and lays them out
# for the Glass Pro module: <outdir>/<dest>/<name>.apk and, for priv apps, the privapp allowlist.
# Usage: tools/fetch_apps.sh <outdir>
# Checks per app: sha256 equals the pin, signer certificate digest equals the pin, package name equals the pin,
# native libs (if any) are stored uncompressed with extractNativeLibs=false (a system app cannot extract them).
# Nothing is written to <outdir> unless every app passes. APKs are copied byte for byte.
# Overrides (tests): BUNDLED_APPS_TSV, DECLARED_PERMS (list for the allowlist filter), AAPT2, APKSIGNER.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=env.sh
. "$ROOT/tools/env.sh"
TSV="${BUNDLED_APPS_TSV:-$ROOT/config/bundled-apps.tsv}"
DECLARED="${DECLARED_PERMS:-$ROOT/config/declared-permissions.txt}"
OUT="${1:?usage: fetch_apps.sh <outdir>}"

die() { echo "fetch_apps: $*" >&2; exit 1; }
sha256() { shasum -a 256 "$1" | cut -d' ' -f1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
stage="$tmp/stage"; mkdir -p "$stage"

while IFS=$'\t' read -r name url sha version dest priv signer pkg; do
  case "$name" in ''|'#'*) continue ;; esac
  apk="$tmp/$name.apk"
  curl -fsSL "$url" -o "$apk" || die "$name: download failed ($url)"
  got="$(sha256 "$apk")"
  [ "$got" = "$sha" ] || die "$name: sha256 mismatch (got $got, pinned $sha)"
  gotsigner="$("$APKSIGNER" verify --print-certs "$apk" 2>/dev/null | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -1)"
  [ "$gotsigner" = "$signer" ] || die "$name: signer certificate mismatch (got ${gotsigner:-none}, pinned $signer)"
  gotpkg="$("$AAPT2" dump packagename "$apk" 2>/dev/null | head -1)"
  [ "$gotpkg" = "$pkg" ] || die "$name: package name mismatch (got $gotpkg, pinned $pkg)"
  python3 -I - "$apk" "$AAPT2" <<'PY' || die "$name: native libs would need extraction"
import subprocess, sys, zipfile
apk, aapt2 = sys.argv[1:3]
libs = [i for i in zipfile.ZipFile(apk).infolist() if i.filename.startswith('lib/') and i.filename.endswith('.so')]
if libs:
    tree = subprocess.run([aapt2, 'dump', 'xmltree', '--file', 'AndroidManifest.xml', apk], capture_output=True, text=True).stdout
    ok = 'extractNativeLibs(0x010104ea)=false' in tree and all(i.compress_type == 0 for i in libs)
    sys.exit(0 if ok else 1)
PY
  mkdir -p "$stage/$dest"
  cp "$apk" "$stage/$dest/$name.apk"
  if [ "$priv" = yes ]; then
    mkdir -p "$stage/system/etc/permissions"
    args=("$stage/$dest/$name.apk" --declared-from "$DECLARED")
    # Droid-ify installs and removes apps silently when privileged; a kept name is listed even if undeclared.
    [ "$pkg" = com.looker.droidify ] && args+=(--keep android.permission.INSTALL_PACKAGES --keep android.permission.DELETE_PACKAGES)
    python3 -I "$ROOT/tools/privapp_xml.py" "${args[@]}" > "$stage/system/etc/permissions/privapp-permissions-$pkg.xml" \
      || die "$name: allowlist generation failed"
  fi
  echo "fetch_apps: $name $version ok" >&2
done < "$TSV"

# Normalise modes, then publish.
find "$stage" -type d -exec chmod 755 {} +
find "$stage" -type f -exec chmod 644 {} +
mkdir -p "$OUT"
cp -R "$stage"/. "$OUT"/
