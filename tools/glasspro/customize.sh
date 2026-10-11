# Glass Pro install-time script, sourced by Magisk's installer (MODPATH is the module's new directory).
# Test overrides: GETPROP (getprop), ADB_DATA (/data/adb), KL_SRC (stock keylayout path).
# Do not `exit` here: use abort.
GETPROP="${GETPROP:-getprop}"
ADB_DATA="${ADB_DATA:-/data/adb}"
KL_NAME=Vendor_0171_Product_0427.kl
KL_SRC="${KL_SRC:-/system/usr/keylayout/$KL_NAME}"

ui_print "- Glass Pro: checking the device"
device="$($GETPROP ro.product.device)"
fp="$($GETPROP ro.build.fingerprint)"
if [ "$device" != karat ]; then
  if [ -e "$ADB_DATA/glass-pro-force" ]; then
    ui_print "! ro.product.device is '$device', not karat: continuing because $ADB_DATA/glass-pro-force exists"
  else
    abort "! Glass Pro is built for the Fire TV Stick 4K 2nd Gen (karat); this is '$device'. Create $ADB_DATA/glass-pro-force to override (contributors only)."
  fi
fi
if [ -f "$MODPATH/fireos-builds.txt" ] && ! grep -qxF "$fp" "$MODPATH/fireos-builds.txt"; then
  if [ -e "$ADB_DATA/glass-pro-force" ]; then
    ui_print "! Fire OS build '$fp' is not on the tested list: continuing because $ADB_DATA/glass-pro-force exists"
  else
    abort "! Fire OS build '$fp' is not on this release's tested list. Create $ADB_DATA/glass-pro-force to override."
  fi
fi

# Remote buttons: the key layout is generated here from the stick's own file, so the zip carries no Amazon file.
# Same edit scripts/remote-keys makes; it is idempotent, so reading a file the old glass-remote-keys module
# already patched gives the same result.
ui_print "- Remote buttons: building the key layout"
if [ -f "$KL_SRC" ]; then
  mkdir -p "$MODPATH/system/usr/keylayout"
  sed -E -e 's/^(key 744[[:space:]]+)APP_1/\1BUTTON_9/' -e 's/^(key 745[[:space:]]+)APP_2/\1BUTTON_10/' \
         -e 's/^(key 746[[:space:]]+)APP_3/\1BUTTON_11/' -e 's/^(key 747[[:space:]]+)APP_4/\1BUTTON_12/' \
         -e 's/^(key 748[[:space:]]+)RECENTS/\1BUTTON_13/' -e 's/^(key 249[[:space:]]+)BUTTON_16/\1SETTINGS/' \
         "$KL_SRC" | grep -v '^key 18[45] ' > "$MODPATH/system/usr/keylayout/$KL_NAME"
  if grep -q BUTTON_9 "$MODPATH/system/usr/keylayout/$KL_NAME"; then
    chmod 644 "$MODPATH/system/usr/keylayout/$KL_NAME"
  else
    ui_print "! Unexpected key layout: remote buttons left as Fire has them"
    rm -rf "$MODPATH/system/usr"
  fi
else
  ui_print "! $KL_SRC not found: remote buttons left as Fire has them"
fi
[ -f "$MODPATH/glass-keymap" ] && chmod 755 "$MODPATH/glass-keymap"
chmod 755 "$MODPATH/service.sh" "$MODPATH/post-fs-data.sh" "$MODPATH/uninstall.sh" 2>/dev/null
[ -f "$MODPATH/keepalive/service.sh" ] && chmod 755 "$MODPATH/keepalive/service.sh"

# Migration, last so a failed check above changes nothing: the three old modules and the two boot scripts
# are replaced by this module, so they must not run a second time (a second Glass instance, a second
# keymap daemon).
ui_print "- Retiring the old Glass modules and boot scripts"
for m in glass-system glass-tuning glass-remote-keys; do
  if [ -d "$ADB_DATA/modules/$m" ]; then
    touch "$ADB_DATA/modules/$m/remove"
    ui_print "  $m: removed on next restart"
  fi
done
for s in start-launcher.sh glass-remote-keepalive.sh; do
  if [ -f "$ADB_DATA/service.d/$s" ]; then
    mkdir -p "$MODPATH/backup"
    mv "$ADB_DATA/service.d/$s" "$MODPATH/backup/$s"
    ui_print "  $s: moved into the module (backup/)"
  fi
done
ui_print "- Done. Restart the TV to apply."
