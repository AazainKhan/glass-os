---
title: FAQ
description: Common questions about Glass, accounts, DRM and updates.
---

## Does Glass work on my Fire TV or Google TV?

Probably, but it has only been tested on the Fire TV Stick 4K (2nd gen). Tell us how it runs with a [device report](https://github.com/AazainKhan/glass-tv-launcher/issues/new?template=device_report.yml).

## Is this the same as tvOS?

No. It is Apple TV-style: similar glass surfaces, focus motion and layout, built independently. It is not affiliated with Apple, Amazon or Google.

## Will Netflix, Prime Video and the like still play?

Yes for the app and the app plus one command: Glass is only a launcher and changes nothing about DRM. Keeping DRM and sign-in intact is an explicit requirement for the rooted and full system installs.

## Can Alexa and Prime Video use different Amazon accounts?

Not today. The account identity is device-wide on Fire OS. Whether a separate account for Prime Video is feasible is unproven, and no account-center is planned until it is checked.

## Will a Fire OS update undo it?

An update can re-enable Amazon's launcher (app plus one command) and can overwrite parts of the system that the rooted and full system installs modify. Updates are best blocked on rooted sticks; an update's bootloader files can also undo an unlocked bootloader.

## Is it safe?

The first two ways change nothing that an uninstall plus one adb command does not undo. The rooted and full system installs can, in the worst case, need a recovery or brick the stick. They are for people comfortable with that.

## Who pays for this?

Nobody. It is free and open source (Apache-2.0).
