---
title: Replacement apps
description: The open-source apps planned for Glass Pro and Glass OS, and why.
---

:::note[Coming soon]
These apps are planned for the Tier 2 and Tier 3 bundles. Nothing here ships yet.
:::

Goal: wherever an Amazon app can be swapped for a faster open-source one, offer the swap. Prime Video, Alexa and the pieces they need for sign-in and DRM stay.

| Role | Choice | Why | Licence |
|---|---|---|---|
| App store | Droid-ify (F-Droid repositories) | Has a TV-friendly entry, updates apps in the background | GPL-3.0-or-later |
| Browser | TV Bro | Works with a remote and uses the system web view for low memory | Custom, redistributed unmodified |
| Optional store | Obtainium | Installs apps straight from GitHub releases | GPL-3.0 |
| Not bundled | Aurora Store | Uses anonymous Play accounts, which risks breakage and terms-of-service trouble; you can still install it from Droid-ify | GPL-3.0 |

Bundled apps are downloaded from upstream, checked against a pinned hash, and never re-signed, so their own updaters keep working.
