---
title: FAQ
description: Common questions about Glass, accounts, DRM and updates.
---

## Does Glass work on my Fire TV or Google TV?

Probably, but it has only been tested on the Fire TV Stick 4K (2nd gen). Tell us how it runs with a [device report](https://github.com/AazainKhan/glass-tv-launcher/issues/new?template=device_report.yml).

## Is this the same as tvOS?

No. It is Apple TV-style: similar glass surfaces, focus motion and layout, built independently. It is not affiliated with Apple, Amazon or Google.

## Will Netflix, Prime Video and the like still play?

Yes on Tiers 0 and 1: Glass is only a launcher and changes nothing about DRM. Keeping DRM and sign-in intact is an explicit requirement for Tiers 2 and 3.

## Can Alexa and Prime Video use different Amazon accounts?

Not today. The account identity is device-wide on Fire OS. Whether a separate account for Prime Video is feasible is unproven, and no account-center is planned until it is checked.

## Will a Fire OS update undo it?

An update can re-enable Amazon's launcher (Tier 1) and can overwrite parts of the system that Tiers 2 and 3 modify. Updates are best blocked on rooted sticks; an update's bootloader files can also undo an unlocked bootloader.

## Is it safe?

Tiers 0 and 1 change nothing that an uninstall plus one adb command does not undo. Tiers 2 and 3 can, in the worst case, need a recovery or brick the stick. They are for people comfortable with that.

## Who pays for this?

Nobody. It is free and open source (Apache-2.0).
