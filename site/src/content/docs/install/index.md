---
title: Install
description: Choose how deep to go. Each tier builds on the one before and says how to undo it.
---

Start at Tier 0 or Tier 1. Most people never need more.

| Tier | You need | What changes | Undo | Status |
|---|---|---|---|---|
| [0: APK](/glass-os/install/tier-0-apk/) | The Fire TV remote, a way to sideload (for example Downloader) | Glass is installed; an accessibility service bounces Amazon's home | Turn the toggle off, uninstall | Available |
| [1: APK + adb](/glass-os/install/tier-1-adb/) | Tier 0, plus a computer with `adb` | Amazon's launcher is disabled for your user, so Home is Glass. Optional permission grants | `adb shell pm enable com.amazon.tv.launcher` | Available |
| [2: Glass Pro](/glass-os/install/tier-2-glass-pro/) | A rooted stick (Magisk) | Magisk module: remote-button remap, tuning, Glass as a system app, systemless debloat | Uninstall the module | Coming soon |
| [3: Glass OS](/glass-os/install/tier-3-glass-os/) | An unlocked bootloader, a custom recovery, your own OTA file | A rebuilt system image | Flash your backup | In development |

Glass is tested on a Fire TV Stick 4K (2nd gen) only. Tiers 2 and 3 are specific to that model today.

**Before any adb step, write down the undo command.** With Amazon's launcher disabled and Glass removed, the stick has no home screen until you re-enable it over adb.
