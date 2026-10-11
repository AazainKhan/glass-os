---
title: "Tier 1: APK + one adb command"
description: Make Glass the real home screen on an unrooted Fire TV, with optional permission grants.
---

You need: Tier 0's APK installed, a computer with [`adb`](https://developer.android.com/tools/releases/platform-tools), and the stick on the same network.

:::caution
Keep the undo command to hand. If Amazon's launcher is disabled and Glass is later removed, the stick has no home screen until you re-enable it over adb.
:::

## Turn on ADB debugging

On the stick: Settings, My Fire TV, About, click the device name seven times to enable Developer options. Then Settings, My Fire TV, Developer options, turn on **ADB debugging**. Find the stick's IP under Settings, My Fire TV, About, Network.

```bash
adb connect STICK_IP:5555
adb devices
```

The first connection shows an authorisation prompt on the TV. Choose Allow.

## Make Glass the home screen

```bash
adb shell pm disable-user --user 0 com.amazon.tv.launcher
```

Press Home. You should land in Glass with no Amazon flash.

**Undo:**

```bash
adb shell pm enable com.amazon.tv.launcher
```

This route relies on `pm disable-user` working from the adb shell without root, which the Glass project believes but has not yet confirmed on an unrooted stick. Amazon's launcher may be re-enabled by an update or factory reset. Run the command again if Home goes back to Amazon.

## Optional adb grants

Everything works without these. Run any you want:

```bash
# Aerials as screensaver, and switch on the Home-button fallback
adb shell pm grant dev.glasslauncher android.permission.WRITE_SECURE_SETTINGS
# Full recent-apps list in the app switcher
adb shell appops set dev.glasslauncher GET_USAGE_STATS allow
# Wi-Fi network name in Control Center
adb shell pm grant dev.glasslauncher android.permission.ACCESS_FINE_LOCATION
```

Two more switches live in system settings: *Notification access* (Now Playing) and the optional accessibility services (*Home Button Takeover*, *Remote Buttons*).

Prefer to have an agent do this? The [runbook](/glass-os/agents/runbook/) covers it with a check after every step.
