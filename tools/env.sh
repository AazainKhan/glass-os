# Source from build scripts: . tools/env.sh
ROM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROM_ROOT
export E2FS="${E2FS:-/opt/homebrew/opt/e2fsprogs/sbin}"
export ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-$HOME/Library/Android/sdk/build-tools/36.0.0}"
export AAPT2="${AAPT2:-$ANDROID_BUILD_TOOLS/aapt2}"
export APKSIGNER="${APKSIGNER:-$ANDROID_BUILD_TOOLS/apksigner}"
export AVBTOOL="${AVBTOOL:-$ROM_ROOT/tools/bin/avbtool.py}"
