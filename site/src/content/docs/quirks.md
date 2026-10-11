---
title: Quirks
description: Facts about the Fire TV Stick 4K (2nd gen) that explain why things work the way they do.
---

These come from the project's own testing on one stick (codename `karat`, Fire OS 8, Android 11).

- **Home is Fire's.** The Home key is handled before any app or accessibility service sees it. Everything Glass does about Home works around that.
- **Remote buttons are Fire's too.** The four app buttons, Recents and Settings are handled inside the system. Reaching them needs a root key remap.
- **No default-launcher picker.** Fire OS offers no "choose your home app" setting. The setting Glass shows on Google TV does not exist here.
- **Only Amazon's screensavers run.** Glass starts Aerials from its own idle timer instead, unless you are rooted or granted the secure-settings permission.
- **Alexa depends on more than it looks like.** Removing `com.amazon.aria` makes Alexa crash on every hold.
- **Prime Video and Alexa share one Amazon account.** Fire OS's account identity is device-wide.
- **Animation scale matters.** Glass's motion is tuned at the system's normal 1.0x animation scale. Lower scales make it look wrong.
- **No volume keys on the stick**, so Magisk safe mode is awkward; use `magisk --remove-modules` over adb.
- **A hold on the remote's Home button for 10 seconds starts pairing.**
