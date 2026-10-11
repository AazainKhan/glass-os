---
title: Ways to install
description: One app, four ways to install it. Start with the first; each later one adds more and says how to undo it.
---

Glass is one app. Pick how much of your Fire TV you want it to take over. Most people should start with the first option.

| Way | You need | What you get | Undo | Status |
|---|---|---|---|---|
| [Install the app](/glass-os/install/app/) | The Fire TV remote and a way to sideload (for example Downloader) | Glass installed, with an accessibility toggle that brings it back over Amazon's home | Turn the toggle off, uninstall | Available |
| [Install + one command](/glass-os/install/app-plus-adb/) | The above, plus a computer with `adb` | Amazon's launcher is disabled for your user, so Home is Glass with no flash. Optional permission grants | `adb shell pm enable com.amazon.tv.launcher` | Available |
| [Rooted install](/glass-os/install/rooted/) | A rooted stick (Magisk) | One Magisk module: Glass as a built-in system app, remote buttons, Control Center over apps, memory tuning | Uninstall the module | Coming soon |
| [Full system install](/glass-os/install/full-system/) | An unlocked bootloader, a custom recovery, your own OTA file | A rebuilt Fire OS image with Glass built in and Amazon's bloat removed | Flash your backup | In development |

Glass is tested on a Fire TV Stick 4K (2nd gen) only. The rooted and full system installs are specific to that model today.

**Before any adb step, write down the undo command.** With Amazon's launcher disabled and Glass removed, the stick has no home screen until you re-enable it over adb.
