---
title: "Tier 2: Glass Pro"
description: A Magisk module for rooted Fire TV Sticks. Coming soon.
---

:::note[Coming soon]
The Glass Pro zip is not built or released yet. This page describes the plan so you can decide whether it is for you. Nothing here should be attempted until a release exists.
:::

## Who it is for

Owners of a rooted Fire TV Stick 4K (2nd gen, codename `karat`) running Magisk. Rooting is its own project and is not covered here.

## What it will do

One Magisk module, `glass-pro`, installed from the Magisk app. Planned contents:

- Glass as a privileged system app, so features like Continue Watching and true force-stop can work.
- Remote-key remap, so the remote's app buttons, Recents and Settings button reach Glass.
- Memory and zram tuning, and a larger cached-app limit.
- A boot script that keeps Glass as home and keeps the remote paired across reboots.
- A **systemless debloat**: Amazon packages that have been checked and found safe to remove are hidden by the module, not deleted. Prime Video, Alexa and the sign-in and DRM pieces stay.
- Droid-ify (an F-Droid store) and TV Bro (a remote-friendly browser), bundled unmodified.

## Safety, as designed

- It refuses to install unless the device is `karat` on a known Fire OS build.
- Uninstalling the module undoes it, including re-enabling Amazon's launcher.
- A bootloop is recoverable with `adb wait-for-device shell magisk --remove-modules`, or by deleting the module from a custom recovery. The stick has no volume keys, so Magisk's safe-mode key combo is unreliable.

Follow [project status](/glass-os/contributing/) for the release. The matching [runbook section](/glass-os/agents/runbook/#tier-2-glass-pro-root-only) lists the checks an agent will run once the zip exists.
