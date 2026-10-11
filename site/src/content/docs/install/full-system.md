---
title: "Full system install"
description: A rebuilt Fire OS image with Amazon's launcher and bloat removed. In development.
---

:::caution[In development]
The full system install is a design, not a release. There is nothing to download or flash yet. Flashing partitions can brick a stick.
:::

## The idea

A deterministic build script that you run against **your own** copy of the Fire OS update file. It removes the evidenced bloat from the system image, bakes Glass in as a system app, and produces a flashable zip. No Amazon files are redistributed: the project publishes scripts and lists only.

It stays Android on Fire OS underneath, so Prime Video, Alexa and DRM keep working.

## Requirements (planned)

- A stick with an unlocked bootloader and a custom recovery already installed.
- Your own OTA file for the exact build the script allows.
- Full partition backups, checked on both sides, before the first write.

## Safety rules the project holds itself to

- Never write the bootloader, preloader, trustzone or vbmeta partitions. Only system, vendor and product images are ever flashed.
- Back up before writing, and rehearse the restore first.
- Three independent ways back: from Android with root, from recovery, and from the bootloader's serial handshake.

The rooted install ships first and is the tested spec for this one.
