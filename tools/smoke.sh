#!/usr/bin/env bash
# Automatic smoke checks for the stick after a Glass Pro install or a Glass OS flash (read-only; adb only).
#   tools/smoke.sh [--upto N] [--manual]
# Exit 0 when every automatic check passes (SKIP is not a failure). --manual also prints the manual checklist,
# taken from the acceptance table in docs/glass-os-spec.md section 4. --upto N: removal batch that must be
# gone from `pm list packages` (default: read from the installed glass-pro module's build-info.txt).
# Environment: ADB (default: adb), CLASSIFICATION (default: config/classification.tsv).
# Take the device lock first when other sessions share the stick (scripts/stick-lock in the Glass repo).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADB="${ADB:-adb}"
CLASSIFICATION="${CLASSIFICATION:-$ROOT/config/classification.tsv}"
UPTO=""; MANUAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --upto) UPTO="$2"; shift 2 ;;
    --manual) MANUAL=1; shift ;;
    *) echo "usage: smoke.sh [--upto N] [--manual]" >&2; exit 2 ;;
  esac
done

fails=0
pass() { echo "PASS $1"; }
fail() { echo "FAIL $1: $2"; fails=$((fails + 1)); }
skip() { echo "SKIP $1: $2"; }
dev() { "$ADB" shell "$@" 2>/dev/null | tr -d '\r'; }
devroot() { "$ADB" shell "su -c '$1'" 2>/dev/null | tr -d '\r'; }

keep_pkgs() { awk -F'\t' '$2 == "KEEP" && $1 !~ /^#/ { print $1 }' "$CLASSIFICATION"; }

# 1. boot finished, and quickly
if [ "$(dev getprop sys.boot_completed)" = 1 ]; then
  ms="$(dev logcat -b events -d | sed -n 's/.*boot_progress_enable_screen: *\([0-9][0-9]*\).*/\1/p' | tail -1)"
  if [ -z "$ms" ]; then skip boot_time "no boot_progress_enable_screen event in the log"
  elif [ "$ms" -lt 120000 ]; then pass "boot_time (${ms} ms)"
  else fail boot_time "screen enabled ${ms} ms after boot (limit 120000)"; fi
else
  fail boot_completed "sys.boot_completed is not 1"
fi

# 2. home is Glass
home="$(dev cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1)"
case "$home" in dev.glasslauncher/*) pass "home ($home)" ;; *) fail home "HOME resolves to '${home:-nothing}'" ;; esac

# 3-6. Wi-Fi, remote, DRM, CEC
dev dumpsys wifi | grep -q 'mNetworkInfo.*CONNECTED' && pass wifi || fail wifi "no connected network in dumpsys wifi"
dev dumpsys bluetooth_manager | grep -qi 'Fire TV Remote' && pass remote_bonded || fail remote_bonded "Fire TV Remote not in dumpsys bluetooth_manager"
dev dumpsys media.drm | grep -qi widevine && pass widevine || fail widevine "Widevine not listed by media.drm"
dev dumpsys hdmi_control | grep -Eqi 'mHdmiControlEnabled: *(true|1)|CEC enabled: *true' && pass hdmi_cec || fail hdmi_cec "CEC not shown as enabled in dumpsys hdmi_control"

# 7. no crash of a KEEP package since boot
pat="$(keep_pkgs | grep -v '^android$' | sed 's/\./\\./g' | paste -sd'|' -)"
crashes="$(dev logcat -b crash -d | grep -E "(^|[^A-Za-z0-9_.])($pat)([^A-Za-z0-9_.]|\$)" | head -3)"
if [ -z "$crashes" ]; then pass no_keep_crashes; else fail keep_crash "crash buffer names a KEEP package: $(echo "$crashes" | head -1)"; fi

# 8. packages: every KEEP present, nothing of the installed removal batch present
installed="$(dev pm list packages | sed 's/^package://')"
missing="$(keep_pkgs | while read -r p; do echo "$installed" | grep -qx "$p" || echo "$p"; done | head -5 | paste -sd' ' -)"
[ -z "$missing" ] && pass keep_packages_present || fail keep_packages_present "missing: $missing"
if [ -z "$UPTO" ]; then
  UPTO="$(devroot 'cat /data/adb/modules/glass-pro/build-info.txt' | sed -n 's/^batches: up to \([0-9a-z]*\).*/\1/p' | head -1)"
fi
if [ -n "$UPTO" ]; then
  gone="$(python3 -I - "$ROOT" "$UPTO" <<'PY'
import os, sys
sys.path.insert(0, os.path.join(sys.argv[1], 'tools'))
from romlib import load_removals
print('\n'.join(p for p, _, _ in load_removals(os.path.join(sys.argv[1], 'config', 'remove-candidates.tsv'), sys.argv[2])))
PY
)"
  still="$(echo "$gone" | while read -r p; do [ -n "$p" ] && echo "$installed" | grep -qx "$p" && echo "$p"; done | head -5 | paste -sd' ' -)"
  [ -z "$still" ] && pass "removed_packages_gone (up to $UPTO)" || fail removed_packages_gone "still installed: $still"
else
  skip removed_packages_gone "no --upto and no glass-pro build-info on the device"
fi

# 9. remote-keys daemon (glass-pro module, or the older glass-remote-keys module)
mods="$(devroot 'ls /data/adb/modules')"
if echo "$mods" | grep -Eqx 'glass-pro|glass-remote-keys'; then
  devroot 'ps -A -o ARGS' | grep -q 'inotifyd.*/dev/input' && pass remote_keys_daemon || fail remote_keys_daemon "module present but no inotifyd on /dev/input"
else
  fail remote_keys_daemon "neither glass-pro nor glass-remote-keys module installed"
fi

# 10. tuning applied
dev settings get global activity_manager_constants | grep -q 'max_cached_processes=12' && pass cached_processes_12 || fail cached_processes_12 "max_cached_processes is not 12"

if [ "$MANUAL" = 1 ]; then
  echo
  echo "Manual checklist (docs/glass-os-spec.md section 4):"
  awk -F'|' '/^## 4\./ { on = 1; next } /^## 5\./ { on = 0 }
             on && /^\| / && $2 !~ /Function/ && $2 !~ /---/ { gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $4); print "- [ ] " $2 ": " $4 }' "$ROOT/docs/glass-os-spec.md"
fi

echo
if [ "$fails" -eq 0 ]; then echo "smoke: all automatic checks passed"; exit 0; fi
echo "smoke: $fails check(s) failed"; exit 1
