#!/system/bin/sh
# Glass Pro late_start script. Each section runs in its own background subshell, so a wait in one never
# delays another. Sections 1 and 2 are the bodies of the former glass-tuning and glass-remote-keys
# service.sh files, ported by copy (see the commit that added this file for the diffs).
MODDIR=${0%/*}
LOG=/data/local/tmp/glass-pro.log
log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; }
boot_done() { until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done; }

# ---- 1. memory tuning (was glass-tuning/service.sh) -------------------------------------------------
tuning() {
# Glass memory tuning. Measured on the Fire TV Stick 4K: apps were cold-started on
# return because Fire OS caps cached apps at 4, lmkd kills the *heaviest* app first (always the video
# app you were just in), and the 800 MB zram fills up. Removing the module restores all three.


resetprop ro.lmk.kill_heaviest_task false
resetprop ro.lmk.psi_partial_stall_ms 300
resetprop ro.lmk.thrashing_limit 200
resetprop ro.lmk.swap_free_low_percentage 3

until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done

stop lmkd; start lmkd
settings put global activity_manager_constants max_cached_processes=12
}

# ---- 2. remote buttons (was glass-remote-keys/service.sh) -------------------------------------------
remote_keys() {
# Frees the remote's Settings button for Glass TV Launcher. Fire OS catches it by its kernel key code
# (249) before apps see it, so the kernel keymap is changed to emit 185 instead, a code the key
# layout doesn't name: it reaches Glass as KEYCODE_UNKNOWN with scan code 185.
# The remote gets a fresh keymap whenever it reconnects (after every sleep), so this re-applies on
# each new input device rather than polling.
BB=/data/adb/magisk/busybox  # its inotifyd takes the :n (created) mask; toybox's rejects it
apply() { "$MODDIR/glass-keymap" remap "Fire TV Remote" 249 185 >/dev/null 2>&1; }
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
apply
while true; do
  "$BB" inotifyd - /dev/input:n | while read -r _; do sleep 1; apply; done
  sleep 5  # inotifyd exited; start watching again
done
}

# Glass's RemoteKeysService (accessibility) must stay enabled for the remapped buttons to reach Glass.
# Same edit scripts/remote-keys makes from the Mac, applied idempotently at every boot.
enable_remote_keys_service() {
  boot_done
  S=dev.glasslauncher/dev.glasslauncher.system.RemoteKeysService
  cur="$(settings get secure enabled_accessibility_services)"
  case "$cur" in
    *"$S"*) ;;
    null|"") settings put secure enabled_accessibility_services "$S" ;;
    *) settings put secure enabled_accessibility_services "$cur:$S" ;;
  esac
  settings put secure accessibility_enabled 1
}

# ---- 3. Glass as home (RECONSTRUCTED from the description in the project notes, not copied) ---------
# Replaces /data/adb/service.d/start-launcher.sh: keep Amazon's launcher off and start Glass through the
# HOME intent. A plain `am start -n` made a second Glass instance; the HOME intent lands in the home task.
start_launcher() {
  boot_done
  pm disable-user --user 0 com.amazon.tv.launcher >/dev/null 2>&1 || true
  pm disable-user --user 0 com.amazon.firehomestarter >/dev/null 2>&1 || true
  cur="$(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -1)"
  case "$cur" in
    dev.glasslauncher/*) ;;
    *) cmd package set-home-activity dev.glasslauncher/.MainActivity ;;
  esac
  pidof dev.glasslauncher >/dev/null || am start -a android.intent.action.MAIN -c android.intent.category.HOME -n dev.glasslauncher/.MainActivity
}

# ---- 4. KEEPALIVE SLOT ------------------------------------------------------------------------------
# The remote keepalive (cancels Fire's AutoPairService re-pair so the sleeping remote stays bonded) is
# being reworked elsewhere; this module does not implement it. In order of preference, this runs:
#   1. keepalive/service.sh in this module (build.sh --keepalive <script> puts the new one there);
#   2. otherwise the old glass-remote-keepalive.sh that customize.sh moved to backup/, verbatim, so an
#      upgrade from the old setup keeps the remote paired;
#   3. nothing, if the separate glass-remote-keepalive module is installed, or a glass-remote-keepalive.sh is
#      back in /data/adb/service.d (the reworked one): those run themselves.
# Never more than one of them.
keepalive_slot() {
  if [ -f "$MODDIR/keepalive/service.sh" ]; then
    log "keepalive: module slot"; sh "$MODDIR/keepalive/service.sh"
  elif [ -d /data/adb/modules/glass-remote-keepalive ] && [ ! -e /data/adb/modules/glass-remote-keepalive/disable ] \
       && [ ! -e /data/adb/modules/glass-remote-keepalive/remove ]; then
    log "keepalive: separate module installed, slot idle"
  elif [ -f /data/adb/service.d/glass-remote-keepalive.sh ]; then
    log "keepalive: script in service.d, slot idle"
  elif [ -f "$MODDIR/backup/glass-remote-keepalive.sh" ]; then
    log "keepalive: legacy script from backup/"; sh "$MODDIR/backup/glass-remote-keepalive.sh"
  else
    log "keepalive: none installed"
  fi
}

( tuning ) &
( remote_keys ) &
( enable_remote_keys_service ) &
( start_launcher ) &
( keepalive_slot ) &
