# User decisions, 2026-10-10

Answers to the open questions in glass-os-spec.md and the ROM plan artifact.

1. **OTA file:** found in ~/Downloads and moved to rom/input/ (same build as the stick).
2. **Option A or B:** the user leaves it to us. Ship first whatever is easiest for a user to install. Decision: **Option A first** (one Magisk zip, "Glass Pro"), then B (flashable image, "Glass OS"). Remote keys, tuning and keepalive stay as Magisk modules in A and get baked in for B.
3. **"Others can install it":** the end goal, not the immediate one. Build, test and document the quirks first. It doesn't have to be 100% done; it's open source and contributions are welcome.
4. **dm-verity off:** yes.
5. **Factory-reset test once backups are proven:** yes.
6. **Strip leftover stock Android apps too:** yes.
7. **BROM / recovery:** the user doesn't know how. We try first from software (adb reboot recovery, TWRP checks) and give them exact physical steps only if a step truly needs hands.
8. **Base OS:** stay Android (Fire OS underneath). Android apps, DRM and streaming services must keep working, so a Linux base is out.
9. **Amazon services:**
   - Prime Video and Alexa stay.
   - Kids is removed.
   - Silk is replaced by an open-source browser that works with a remote.
   - Goal: every Amazon app can be swapped for a faster open-source alternative.
10. **App store:** a popular open-source Android store built in, so users don't need Downloader.
    - Candidates: Aurora Store (Play Store front end), F-Droid / Droid-ify, Obtainium.
    - Sideloading stays as an option.
    - Amazon Appstore pieces that apps need for DRM and sign-in stay.
11. **Account center:** an Android-style account center that lets Alexa and Prime use separate Amazon accounts. Feasibility unknown: Fire OS's MAP identity is device-wide. Research it.
12. **Docs site:** a clean, human-readable docs site that is also agent-readable (llms.txt, step-by-step install runbooks a Claude Code session can follow against a stick). It doubles as the marketing site.
13. **Kernel and hardware control:** welcome where the image work allows it.
