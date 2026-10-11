---
title: "Install the app"
description: Sideload Glass and switch on Home Button Takeover. No computer needed.
---

You need: a Fire TV (or Android TV / Google TV) on Android 9 or newer, and a way to sideload an APK. Fire TV users usually use the Downloader app.

## Steps

1. Download the latest APK from the [Glass releases page](https://github.com/AazainKhan/glass-tv-launcher/releases). Sideload it (for Downloader, enter the release URL, then allow "Install unknown apps" for it when asked).
2. Open **Glass TV Launcher** from your apps.
3. Make it your home screen:
   - **Google TV / Android TV:** Settings, Home Button, *Make Glass TV Launcher the Default*.
   - **Fire TV:** Fire OS has no default-launcher picker. In Glass, open Settings, then Home Button, and turn on *Home Button Takeover*. If Glass cannot switch the accessibility service on itself, enable "Glass TV Launcher" in the TV's Accessibility settings.

## What to expect on Fire TV

Pressing Home still goes to Amazon's launcher first, then Glass opens over it about a moment later. That is a limit of Fire OS, not a bug. If the flash bothers you, use [Install + one command](/glass-os/install/app-plus-adb/), which removes the flash.

The service only watches for Amazon's launcher windows. It does not read your screen or filter keys.

## Undo

Turn off *Home Button Takeover*, then uninstall Glass from Settings, Applications. Nothing else was changed.

See [What works without root](/glass-os/no-root/) for the full feature list.
