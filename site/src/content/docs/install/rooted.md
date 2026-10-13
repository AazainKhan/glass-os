---
title: "Glass Pro (rooted install)"
description: Glass on a rooted Fire TV Stick as a privileged system app, with the remote keymap, a pairing keepalive and memory tuning. Works today from source; the one-zip release is coming soon.
---

:::caution[Advanced, from source]
Glass Pro works today, but you install it from the Glass source repository with scripts, one Magisk module at a time. It has run on one stick: the maintainer's rooted Fire TV Stick 4K. **The single downloadable Magisk zip, a release, and a test on any other stick do not exist yet** (the one-zip release is coming soon). If you are not comfortable recovering a stick from a bad module, use [Install + one command](/glass-os/install/app-plus-adb/) instead.
:::

## Who it is for

Owners of a rooted Fire TV Stick 4K (2nd gen, codename `karat`) running Magisk, with a computer that has `adb`. Rooting is its own project and is not covered here.

## What you need

- A rooted stick with Magisk. Check with `adb shell su -c id`; you should see `uid=0(root)` (accept the Magisk prompt on the TV).
- ADB debugging on, and the stick reachable from your computer.
- A clone of the [Glass source repository](https://github.com/AazainKhan/glass-tv-launcher) and its build setup (JDK 21) for the scripts below. Run every command from the repository root.
- The undo commands from this page written down before you start.

## The four modules

Glass Pro is four Magisk modules. Each can be installed and removed on its own. Glass also gets a Magisk `su` grant, which the root-only features use.

| Module | What it does | Install | Uninstall |
|---|---|---|---|
| `glass-system` | Glass becomes a privileged system app, so features that need system permissions can work (for example Continue Watching). | `scripts/build`, which runs `scripts/privapp-check` first | Remove the module in Magisk |
| `glass-remote-keys` | Remaps the remote's four app buttons, Recents and Settings so Glass can map them. Also needs Glass's accessibility service on. | `scripts/remote-keys install [--reboot]` | `scripts/remote-keys uninstall [--reboot]` |
| `glass-remote-keepalive` | Keeps the remote paired across reboots by answering Fire's 60 second re-pair timer with one key event. | `scripts/remote-keepalive install [--reboot]` | `scripts/remote-keepalive uninstall [--reboot]` |
| `glass-tuning` | Memory: 1.2 GB zram, least-recently-used-first lmkd, 12 cached apps instead of 4. | `scripts/tuning install [--reboot]` | `scripts/tuning uninstall [--reboot]` |

Each script also takes `status`. All of them take effect after a restart.

### glass-system

Fire OS checks privileged apps against a permission allowlist at boot. A single permission Glass requests that the module does not list stops the system from booting. `scripts/build` therefore runs `scripts/privapp-check <apk>` before it installs: it adds any missing entries to the module's allowlist (it only adds, and saves the old file as a backup), reads the result back, and refuses to continue if the list does not cover the APK. Do not install Glass over `glass-system` by any other route.

The module itself is created from inside Glass (Settings, Root, System App), which copies the APK into a Magisk module. Removing the module reverts Glass to a normal app.

### glass-remote-keys

Fire OS handles the remote's app buttons, Recents and Settings inside the system, so no app sees them. This module overlays the remote's key layout so those buttons arrive as keys Glass's accessibility service can read, and rewrites the remote's kernel keymap for the Settings button. Everything else on the remote is unchanged. Turn Glass's accessibility service on (the script tries to enable it for you), then map the buttons in Glass's Settings, Remote Buttons.

### glass-remote-keepalive

Fire's auto-pair service re-pairs about 60 seconds after boot, which can drop a sleeping remote's bond. The module watches that service's log and sends one key event whenever it arms its timer. It replaces an older boot script with a fixed 15 second timer, and the install removes that script. Without it, Fire shows its auto-pair dialog after reboots until a key is pressed. To pair a remote from scratch: reboot, wait about 60 seconds for Fire's auto-pair dialog, then hold Home for 10 seconds.

### glass-tuning

Fire OS turns on 800 MB of zram at boot; the module overlays that setting with 1.2 GB, and its boot script sets the lmkd and the cached-app limit. Uninstall also puts `max_cached_processes` back to 4, because that is a stored setting rather than part of the module.

## Install

1. Confirm root and the device (see the requirements above).
2. Install `glass-system`: run `scripts/build` (the release variant by default). Watch for `privapp-check` to finish without refusing.
3. Install the others you want, for example `scripts/remote-keys install`, `scripts/remote-keepalive install` and `scripts/tuning install`. Add `--reboot` to restart straight away.
4. After the restart, run `scripts/remote-keys status`, `scripts/remote-keepalive status` and `scripts/tuning status` to confirm each module is installed.

The [agent runbook](/glass-os/agents/runbook/#rooted-install-root-only) has the same steps with a check after each.

## Revert

- One module: run its `uninstall` command, then restart. The module is removed at the next boot.
- `glass-system`: remove the module in the Magisk app (or `adb shell su -c "touch /data/adb/modules/glass-system/remove"`), then restart. *Untested: this revert has not been run on a stick yet.*
- Bootloop: from a computer, `adb wait-for-device shell magisk --remove-modules`. If adb never comes up, delete the module directories from a custom recovery. The stick has no volume keys, so Magisk's safe-mode key combo is unreliable.
- If Glass was your only home screen and it is gone, `adb shell pm enable com.amazon.tv.launcher` brings Amazon's launcher back.

## What is not done

- No single Magisk zip yet (coming soon). Each module is installed by its own script.
- No release and no prebuilt files. You build from source.
- Tested only on the maintainer's Fire TV Stick 4K. Nobody has reported another stick or Fire OS build.
- Updates: a Fire OS update can overwrite parts of the system that the modules change. Block updates on a rooted stick.

Follow [project status](/glass-os/contributing/) for the release.
