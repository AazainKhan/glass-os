# Glass Pro

One Magisk module for the Fire TV Stick 4K 2nd Gen (karat, Fire OS 8): Glass TV Launcher as a privileged home
app, memory tuning, remote button mapping, remote keepalive slot, a systemless debloat, and a bundled store
(Droid-ify) and browser (TV Bro). It contains no Amazon file: the debloat hides packages with empty
`.replace` directories, and the key layout is generated on your stick at install time.

## Install

Needs a rooted stick (Magisk 20.4 or newer). Magisk app: Modules > Install from storage > pick the zip, or
`adb push` it and run `su -c 'magisk --install-module /data/local/tmp/<zip>'`. Restart.
Installing over the older Glass setup is handled: `glass-system`, `glass-tuning` and `glass-remote-keys` are
marked for removal, and `start-launcher.sh` and `glass-remote-keepalive.sh` are moved from
`/data/adb/service.d` into this module (`backup/`) so nothing runs twice. They are also copied to
`/data/adb/glass-pro-backup/`, which survives upgrades and removal of the module.
Refuses to install on other devices or untested Fire OS builds; contributors can create
`/data/adb/glass-pro-force` to continue anyway.

## Uninstall

Magisk app > Modules > remove, then restart. A one-shot script restores `max_cached_processes=4`, re-enables
Amazon's launcher and undoes the remote keymap change after the next boot. The two old boot scripts are not
brought back; to return to the old setup copy them from `/data/adb/glass-pro-backup/` into
`/data/adb/service.d/` and reinstall the three old modules.

## If it bootloops

The stick has no volume keys, so Magisk's safe mode is unreliable. From a computer:
`adb wait-for-device shell magisk --remove-modules` while it loops, or from recovery
`rm -rf /data/adb/modules/glass-pro`.

## Source and licences

See `THIRD_PARTY.md`. Droid-ify is GPL-3.0-or-later and is shipped as the unmodified upstream APK; its source is
https://github.com/Droid-ify/client (tag v0.7.8). TV Bro is shipped as the unmodified upstream release.
