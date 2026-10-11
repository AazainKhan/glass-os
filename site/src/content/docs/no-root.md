---
title: What works without root
description: Exactly what Glass does on a stock, unrooted Fire TV, and what needs a computer or root.
---

This page is worked out from reading the Glass source (master as of 2026-10-10). **It was not run on an unrooted stick**: the only test stick is rooted. Treat the "Needs" column as the code's intent and tell us if your stick disagrees ([device report](https://github.com/AazainKhan/glass-tv-launcher/issues/new?template=device_report.yml)).

"Needs adb" means a one-time command from a computer with ADB debugging switched on. It needs no root.

| Area | Unrooted | Needs |
|---|---|---|
| Glass as the home screen | Partly: a bounce, not a takeover | the accessibility toggle, or adb to disable Amazon's launcher |
| Intercepting the Home button | No, on any unrooted setup | Fire's key policy takes it before any app |
| Control Center from Home (status pill) | Yes | nothing |
| Control Center over other apps | No | the remote's Settings button, which only reaches Glass with root |
| Remote app buttons, Recents, Settings button | No | root key remap (rooted install) |
| App switcher | Yes, from Control Center | one adb grant for the full list |
| Fire TV app art, Continue Watching | No | root |
| Icon packs | List and apply: yes. Installing a downloaded pack: no | install it with Downloader instead |
| Rows, featured shelf, folders, move/hide, themes, widgets, Aerials, updates | Yes | nothing |

## Home screen: a bounce, not a takeover

With *Home Button Takeover* on, Glass watches for Amazon's launcher coming to the front and starts itself over it about 800 ms later. Pressing Home still goes to Amazon first, so expect the stock home to flash briefly. Nothing better exists on Fire OS: the system takes Home presses before any app or accessibility service sees them.

The reliable no-root route is the adb command in [Install + one command](/glass-os/install/app-plus-adb/), which disables Amazon's launcher so Home resolves to Glass. If Amazon's launcher comes back (an update, a factory reset), repeat the command.

## Control Center

Opened from the status pill on Glass's home screen it works without any permission. Tiles that work: Wi-Fi, Bluetooth, Settings, Launcher Settings, App Switcher, Smart Home (if the package exists). Some Fire TV settings sections fall back to the plain Android settings page. **Ask Alexa** opens something that closes at once, so treat it as not working. **Alexa Settings**, **Performance** and **Free Memory** are root only and hidden when unrooted. The AirPlay tile needs the separate PhairPlay app.

## Remote buttons

Fire OS handles the four app buttons, Recents and Settings inside the system, so no app sees them. Remapping them needs a root Magisk module (part of the [rooted install](/glass-os/install/rooted/), coming soon). Unrooted, the accessibility service can still give you "hold Back for 1.5 s to go Home" and app-switcher preview screenshots.

## Closing apps

The app switcher's close button ends the app's background processes only. A normal app cannot truly force-stop another, so the system may restart it. The card still leaves the switcher.

## Optional one-time grants (no root)

| Feature | Command or page | Without it |
|---|---|---|
| Aerials as the system screensaver, Home fallback on | `WRITE_SECURE_SETTINGS` grant | Glass starts Aerials from its own idle timer while Glass is in front (Fire OS only runs Amazon's screensavers anyway) |
| Full recent-apps list | `GET_USAGE_STATS` appop | only apps opened from Glass |
| Wi-Fi name in Control Center | `ACCESS_FINE_LOCATION` grant | shows "Connected" |
| Now Playing card | Notification access, in system settings | no Now Playing |
| In-app updates | "Install unknown apps" for Glass | prompts each time |

The exact commands are in [Install + one command](/glass-os/install/app-plus-adb/#optional-adb-grants).
