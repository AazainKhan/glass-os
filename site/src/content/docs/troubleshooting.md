---
title: Troubleshooting
description: Symptoms, causes and fixes for Glass on Fire TV.
---

Fixes marked **Root** need a rooted stick.

## Home goes to Amazon's launcher, or Glass flashes after it

**Cause.** Unrooted, Glass can only bounce Amazon's launcher out of the way; Fire OS keeps the Home key for itself.
**Fix.** Use [Install + one command](/glass-os/install/app-plus-adb/): `adb shell pm disable-user --user 0 com.amazon.tv.launcher`. If it was working and stopped, an update or reset probably re-enabled Amazon's launcher: run the command again.

## The stick has no home screen

**Cause.** Amazon's launcher is disabled and Glass is gone or crashing.
**Fix.** `adb shell pm enable com.amazon.tv.launcher`.

## The remote will not pair, or unpairs after a reboot

**Pairing from scratch.** Reboot the stick and wait about 60 seconds for Fire's auto-pair dialog, then **hold the Home button for 10 seconds** on the remote.
**Cause of unpairing (Root).** Fire's auto-pair service re-pairs about 60 seconds after boot, which can drop a sleeping remote's bond. Glass Pro includes a keepalive module that cancels this: `scripts/remote-keepalive install` from the [Glass source repo](/glass-os/install/rooted/).

## Alexa crashes whenever you hold the mic button

**Cause.** The debloat removed `com.amazon.aria`, which Alexa needs (the error is "windowTemplateId cannot be null").
**Fix.** `adb shell cmd package install-existing com.amazon.aria`. Keep that package.

## Two copies of Glass start

**Cause.** The launcher was started with `am start -n`. Start it through the Home intent instead (Glass Pro does this).

## The stick bootloops after installing a Magisk module (Root)

**Fix.** From a computer: `adb wait-for-device shell magisk --remove-modules`. If adb never comes up, use a custom recovery and delete the module directory. The stick has no volume keys, so Magisk's safe-mode key combo is unreliable.

## Control Center does not open over apps, or the app buttons do nothing

**Cause.** The remote's Settings, Recents and app buttons never reach third-party apps on stock Fire OS.
**Fix (Root).** The `glass-remote-keys` module in [Glass Pro](/glass-os/install/rooted/) (`scripts/remote-keys install`). See [What works without root](/glass-os/no-root/).

## A privileged app stops the stick booting (rooted and full system installs)

**Cause.** The system enforces a permission allowlist for privileged apps; one missing entry halts boot.
**Fix.** Remove the module from recovery or with `magisk --remove-modules`, then report it.

## Still stuck?

Open an issue with your device model, Fire OS version and the step that failed. Remove any serial numbers and home-directory paths from pasted output first.
