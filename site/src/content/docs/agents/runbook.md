---
title: Runbook
description: Short, verifiable install steps for an agent working against a connected Fire TV Stick.
---

Read [For agents](/glass-os/agents/) for the safety rules first. Each step: **Do**, **Verify** (expected output below it), **If it fails**. "contains" means a substring match is enough. Stop and ask the user whenever a step says **Ask user**.

```bash
export GLASS_APK="$HOME/Downloads/glass-tv-launcher.apk"
```

With more than one device, add `-s SERIAL` to every `adb` command.

## Tier 1: APK + adb

### 1. Reach the stick

```bash
adb get-state
```

```text
device
```

If it fails: `unauthorized` means **Ask user** to accept the prompt on the TV. No device means ask for the stick's IP, then `adb connect STICK_IP:5555`.

### 2. Check the model

```bash
adb shell getprop ro.product.device
```

```text
karat
```

If it fails: another value is an untested device. **Ask user** before continuing. Never run Tier 2 or 3 on it.

### 3. Install the APK

**Ask user** to approve.

```bash
test -f "$GLASS_APK" && adb install -r "$GLASS_APK"
```

```text
Success
```

Verify:

```bash
adb shell pm list packages dev.glasslauncher
```

```text
package:dev.glasslauncher
```

If it fails: `adb uninstall dev.glasslauncher`, then stop.

### 4. Note the current home

```bash
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
```

```text
last line names the current home, normally com.amazon.tv.launcher/...
```

Write it down as the "before" value.

### 5. Make Glass the home screen

**Ask user** to approve disabling Amazon's launcher.

```bash
adb shell pm disable-user --user 0 com.amazon.tv.launcher
```

```text
contains: new state: disabled-user
```

Verify:

```bash
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
```

```text
last line starts with: dev.glasslauncher/
```

If it fails: `adb shell pm enable com.amazon.tv.launcher`, then stop.

### 6. Home reaches Glass

```bash
adb shell input keyevent KEYCODE_HOME
adb shell dumpsys activity activities | grep -m1 topResumedActivity
```

```text
contains: dev.glasslauncher
```

If it fails: roll back as in step 5, then stop.

### 7. Optional grants

**Ask user** which of these they want. Run only those.

```bash
adb shell pm grant dev.glasslauncher android.permission.WRITE_SECURE_SETTINGS
adb shell appops set dev.glasslauncher GET_USAGE_STATS allow
adb shell pm grant dev.glasslauncher android.permission.ACCESS_FINE_LOCATION
```

Verify:

```bash
adb shell dumpsys package dev.glasslauncher | grep -E "WRITE_SECURE_SETTINGS|ACCESS_FINE_LOCATION"
adb shell appops get dev.glasslauncher GET_USAGE_STATS
```

```text
each granted permission line contains: granted=true
GET_USAGE_STATS: allow
```

If it fails: `adb shell pm revoke dev.glasslauncher android.permission.WRITE_SECURE_SETTINGS` (same for the others), then stop.

## Tier 2: Glass Pro (root only)

:::note[Coming soon]
The Glass Pro zip does not exist yet. R1 and R2 check readiness and can run today. Do not run R3 until a release is announced.
:::

### R1. Root works (Root only)

**Ask user** to accept the Magisk prompt on the TV.

```bash
adb shell su -c id
```

```text
contains: uid=0(root)
```

If it fails: stop. Skip every root-only step.

### R2. Magisk is present (Root only)

```bash
adb shell su -c "magisk -c"
```

```text
a non-empty version string, for example 30.7:MAGISKSU
```

If it fails: stop.

### R3. Install the module (Root only, coming soon)

**Ask user** to approve the install and a reboot. Command: coming soon.

```bash
adb shell su -c "ls /data/adb/modules/glass-pro"
```

```text
contains: module.prop
```

If it fails: `adb wait-for-device shell su -c "magisk --remove-modules"`, then stop. If adb never returns, **Ask user**: a custom recovery is needed.

## Tier 3: Glass OS

Coming soon. Do not attempt.
