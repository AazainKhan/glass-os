#!/system/bin/sh
# Runs when Magisk removes the module, early in boot, before the framework is up: `settings` and `pm`
# do not work yet. So this only stages a one-shot script in service.d that waits for boot to finish,
# puts Fire OS back and deletes itself. The module's files (key layout overlay, zram size, replaced
# Amazon packages, Glass priv-app) disappear with the module directory.
# Not restored (they belonged to the old setup): /data/adb/service.d/start-launcher.sh and
# glass-remote-keepalive.sh. Their copies were in this module's backup/ directory, which is gone now.
MODDIR=${0%/*}
ADB_DATA="${ADB_DATA:-/data/adb}"
STAGE="$ADB_DATA/glass-pro-restore"
mkdir -p "$STAGE" "$ADB_DATA/service.d"
[ -f "$MODDIR/glass-keymap" ] && cp "$MODDIR/glass-keymap" "$STAGE/glass-keymap" && chmod 755 "$STAGE/glass-keymap"
cat > "$ADB_DATA/service.d/glass-pro-restore.sh" <<RESTORE
#!/system/bin/sh
until [ "\$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
# Fire OS's cached-app cap (a stored setting, not part of the module).
settings put global activity_manager_constants max_cached_processes=4
# Amazon's launcher back on (it was disabled; if it was removed from the image these are no-ops).
pm enable com.amazon.tv.launcher >/dev/null 2>&1
pm enable com.amazon.firehomestarter >/dev/null 2>&1
# Fire's key behaviour: the key layout overlay is gone with the module; undo the live kernel keymap change too.
[ -x "$STAGE/glass-keymap" ] && "$STAGE/glass-keymap" remap "Fire TV Remote" 185 249 >/dev/null 2>&1
rm -rf "$STAGE" "$ADB_DATA/service.d/glass-pro-restore.sh"
RESTORE
chmod 755 "$ADB_DATA/service.d/glass-pro-restore.sh"
