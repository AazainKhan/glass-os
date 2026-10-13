---
title: Runbook
description: Short, verifiable install steps for an agent working against a connected Fire TV Stick.
---

Read [For agents](/glass-os/agents/) for the safety rules first. Each step: **Do**, **Verify** (expected output below it), **If it fails**. "contains" means a substring match is enough. Stop and ask the user whenever a step says **Ask user**.

```bash title="Terminal"
export GLASS_APK="$HOME/Downloads/glass-tv-launcher.apk"
```

With more than one device, add `-s SERIAL` to every `adb` command.

## Install + one command

### 1. Reach the stick

```bash title="Terminal: adb"
adb get-state
```

```text title="Expected output"
device
```

If it fails: `unauthorized` means **Ask user** to accept the prompt on the TV. No device means ask for the stick's IP, then `adb connect STICK_IP:5555`.

### 2. Check the model

```bash title="Terminal: adb"
adb shell getprop ro.product.device
```

```text title="Expected output"
karat
```

If it fails: another value is an untested device. **Ask user** before continuing. Never run the rooted or full system install on it.

### 3. Install the APK

**Ask user** to approve.

```bash title="Terminal: adb"
test -f "$GLASS_APK" && adb install -r "$GLASS_APK"
```

```text title="Expected output"
Success
```

Verify:

```bash title="Terminal: adb"
adb shell pm list packages dev.glasslauncher
```

```text title="Expected output"
package:dev.glasslauncher
```

If it fails: `adb uninstall dev.glasslauncher`, then stop.

### 4. Note the current home

```bash title="Terminal: adb"
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
```

```text title="Expected output"
last line names the current home, normally com.amazon.tv.launcher/...
```

Write it down as the "before" value.

### 5. Make Glass the home screen

**Ask user** to approve disabling Amazon's launcher.

```bash title="Terminal: adb"
adb shell pm disable-user --user 0 com.amazon.tv.launcher
```

```text title="Expected output"
contains: new state: disabled-user
```

Verify:

```bash title="Terminal: adb"
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
```

```text title="Expected output"
last line starts with: dev.glasslauncher/
```

If it fails: `adb shell pm enable com.amazon.tv.launcher`, then stop.

### 6. Home reaches Glass

```bash title="Terminal: adb"
adb shell input keyevent KEYCODE_HOME
adb shell dumpsys activity activities | grep -m1 topResumedActivity
```

```text title="Expected output"
contains: dev.glasslauncher
```

If it fails: roll back as in step 5, then stop.

### 7. Optional grants

**Ask user** which of these they want. Run only those.

```bash title="Terminal: adb"
adb shell pm grant dev.glasslauncher android.permission.WRITE_SECURE_SETTINGS
adb shell appops set dev.glasslauncher GET_USAGE_STATS allow
adb shell pm grant dev.glasslauncher android.permission.ACCESS_FINE_LOCATION
```

Verify:

```bash title="Terminal: adb"
adb shell dumpsys package dev.glasslauncher | grep -E "WRITE_SECURE_SETTINGS|ACCESS_FINE_LOCATION"
adb shell appops get dev.glasslauncher GET_USAGE_STATS
```

```text title="Expected output"
each granted permission line contains: granted=true
GET_USAGE_STATS: allow
```

If it fails: `adb shell pm revoke dev.glasslauncher android.permission.WRITE_SECURE_SETTINGS` (same for the others), then stop.

## Rooted install (root only)

:::caution[Advanced, from source]
Glass Pro is installed from the Glass source repository (a clone, with JDK 21, run from its root). There is no single zip or release yet (coming soon), and it has only run on the maintainer's stick.
:::

### R1. Root works (Root only)

**Ask user** to accept the Magisk prompt on the TV.

```bash title="Terminal: adb"
adb shell su -c id
```

```text title="Expected output"
contains: uid=0(root)
```

If it fails: stop. Skip every root-only step.

### R2. Magisk is present (Root only)

```bash title="Terminal: adb"
adb shell su -c "magisk -c"
```

```text title="Expected output"
a non-empty version string, for example 30.7:MAGISKSU
```

If it fails: stop.

### R3. Install the Glass Pro modules (Root only)

**Untested:** these steps have not been run end to end on a stick yet; stop and report at the first unexpected output.

**Ask user** to approve the install and each reboot. Run from the root of the Glass source repository.

```bash title="Terminal: adb"
scripts/build
scripts/remote-keys install
scripts/remote-keepalive install
scripts/tuning install --reboot
adb wait-for-device
```

Verify after the stick has booted:

```bash title="Terminal: adb"
adb shell su -c "ls /data/adb/modules"
scripts/remote-keys status
scripts/remote-keepalive status
scripts/tuning status
```

```text title="Expected output"
modules contains: glass-system glass-remote-keys glass-remote-keepalive glass-tuning
keepalive status: module: installed
tuning status: module installed
```

If it fails: `adb wait-for-device shell su -c "magisk --remove-modules"`, then stop. If adb never returns, **Ask user**: a custom recovery is needed. To remove one module, run its `uninstall` command and restart.

## Full system install

Coming soon. Do not attempt.
