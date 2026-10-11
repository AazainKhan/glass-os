# Custom-ROM tooling research: Fire TV Stick 4K 2nd Gen (karat)

Research date: 2026-10-10. Planning only. No exploit details. Root is already in place (Magisk 30.7 on Fire OS 8.1.8.2 / Android 11).

Confidence key: [S] = stated in a fetched primary source. [W] = from search snippets only. [U] = unverified, my inference.

**Coverage gap up front:** I found no karat-specific prior art, no karat TWRP build, and no karat amonet guide. The XDA threads for mantis and Sheldon returned HTTP 403 to my fetcher, so their contents are unread. Treat everything device-specific below as unverified until checked on your own device.

## 1. Converting .new.dat.br to raw images, and reading them on macOS

- Pipeline: `brotli -d system.new.dat.br` gives `system.new.dat`. Then `sdat2img.py system.transfer.list system.new.dat system.img` gives a raw ext4 image. [S] https://github.com/xpirt/sdat2img (usage, Python 2.7+, macOS supported, does NOT read .br directly, must be decompressed first)
- Brotli on macOS: `brew install brotli`. [W] Source is a LineageOS/e.foundation wiki list, https://wiki.lineageos.org/extracting_blobs_from_zips_manually and https://doc.e.foundation/os/advanced/extracting-proprietary-blobs
- Alternate sdat2img fork: https://github.com/YorokobiMaster/sdat2img (same usage, same .br caveat). [S]
- Caveat: system.img from sdat2img is ext4 for most stock images, but Amazon may ship EROFS for some partitions. Check with `file` or `dump.erofs`/`dumpe2fs` before choosing a tool. [U]
- Extract without mounting (no root, no kernel mount on macOS):
  - ext4: `debugfs -R 'rdump / outdir' system.img` (e2fsprogs from Homebrew). [U] Verify on your image.
  - EROFS: erofs-utils from Homebrew (`formulae.brew.sh/formula/erofs-utils`). Use `fsck.erofs --extract=<dir> image` or `erofsfuse` (userspace, no kernel mount). [W] https://android.googlesource.com/platform/external/erofs-utils/+/5df285c/README and https://github.com/ipearworks/erofs-utils. Whether all of it builds on macOS is not confirmed.
  - 7z also reads raw ext4 and some EROFS on macOS (`brew install p7zip`). [U]
- Sparse images (`simg2img`) may be needed before lpunpack or the unpacker. [W] https://github.com/jamshid-ds/android-payload-toolkit covers super/payload handling.

## 2. Rebuilding and flashing dynamic partitions

- Your OTA has `dynamic_partitions_op_list`, so partitions live inside `super`. Rebuild per-partition images, then repack `super` with lpmake. [S] AOSP partition tools README: https://android.googlesource.com/platform/system/extras/+/refs/heads/android11-dev/partition_tools/
  - lpmake: `lpmake` needs device size exactly matching the super partition, sector-aligned (512 B). Outputs sparse for fastboot, or metadata-only for lpflash. Required args and metadata sizing in the README above.
  - lpdump: inspect metadata of a super image.
  - lpadd: add a partition image to an existing super, or to a super_empty image. Useful for swapping one partition without rebuilding all of them.
- lpunpack: `lpunpack [-p NAME] [-S SLOT] super.img outdir/`. Build it from AOSP `system/extras/partition_tools` (`m lpunpack`) or take it from an otatools bundle. There is no Homebrew formula that I could confirm. [W] https://wiki.lineageos.org/extracting_blobs_from_zips (lpunpack build), https://manpages.opensuse.org/Tumbleweed/android-tools-partition/lpunpack.1
- Alignment: the default is 1 MiB. The AOSP doc says super must align to the minimum I/O size. Check the device's block size first. [S] AOSP doc above.
- Size limit: a rebuilt partition must fit its slot in the super table. Growing `system` means shrinking another partition or using free space (`lpdump` shows free space). [U] Shared-block ext4 is the common cause of "image too large" errors. Set the ext4 size by `resize2fs` or rebuild with `mke2fs`.
- Flashing: with unlocked bootloader and amonet, use `fastboot flash super super.img` (sparse), or flash individual logical partitions if the bootloader accepts it. Whether karat's fastboot accepts logical-partition flashing is unverified. [U]
- Read-only issue: Android's read-only `system` on ext4 comes from `ro` flags in the fstab and from verity. A fully repacked system is the usual fix. [U]

## 3. AVB / dm-verity: does a modified system require disabling verification?

- Verity is enforced by vbmeta. If a modified system is flashed without changes, boot fails when verification fails. The usual workaround is to flash a vbmeta with verification disabled. [S] Mechanism and flags: https://gerrit.omnirom.org/plugins/gitiles/android_system_core/+/df6a780ee72999730826be6a00b437e0a97ebab9%5E%21 (flags at offset 120: bit0 = disable-verity, bit1 = disable-verification).
- Typical command for AVB 2.0 devices: `fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img`. Reports say `--disable-verification` alone can bootloop, and that the flash can fail if userdata encryption is on. [W] https://www.hovatek.com/forum/post-188641.html , https://www.hovatek.com/forum/post-240717.html
- Practical rules: use the vbmeta from the exact firmware build, keep a stock vbmeta backup, and check whether your bootloader honours these flags at all. [W]
- Whether karat's bootloader (amonet) and Fire OS 8 honour these flags is unverified. [U]
- Modified boot image: Magisk patches boot.img, so vbmeta must still allow boot.img. The Magisk/vbmeta interaction for Fire TV is not documented in what I could fetch. [U]

## 4. Prior art: custom ROMs and debloated images for Fire TV

- Mantis (Fire TV Stick 4K, 2018) pre-rooted Android TV ROM by burcbuluklu, on XDA. Guide: unlock, install TWRP, restore backup. [W] https://forum.xda-developers.com/t/guide-rom-mantis-fire-tv-stick-4k-prerooted-android-tv-rom-6-2-7-6.4208859/ (403 on fetch; text from search snippets). Firmware target 6.2.7.6 (Fire OS 6), not Fire OS 8.
- Sheldon ("Tweaked + Google Play + Debloated") ROM, for 3rd-gen stick, on XDA. Firmware 7.2.4.9 in the title. Listed as beta, Android 9. [W] https://forum.xda-developers.com/t/rom-sheldon-fire-tv-stick-tweaked-google-play-debloated-7-2-4-9.4514749/ (403 on fetch).
- AFTVNews: root and TWRP for 3rd-gen and Lite requires Fire OS 7.2.7.3 or older. [W] https://www.aftvnews.com/?p=38677 (article cited in search, not opened). This is the firmware ceiling that kills older root paths on newer sticks.
- tank-convert (2nd-gen stick, "tank"): amonet-based tooling with Magisk, not karat. [W] https://github.com/kerta1n/tank-convert
- /e/OS build for mantis (Nougat): [W] https://community.e.foundation/t/custom-build-amazon-fire-tv-stick-4k-mantis-for-e-os-nougat/57337
- None of these covers Fire OS 8 or karat. The "what broke" details live in the XDA threads, which I could not read.

Note on the 403s: retry from a browser or an authenticated fetch; I did not work around the block.

## 5. Recovery: TWRP and full-partition backup

- TWRP for karat: not found. I could not confirm a karat build on twrp.me. [W] Mantis has used TWRP 3.6.1_9-0 per an XDA snippet. Check twrp.me/devices for the codename `karat` first. (Search source: https://forum.xda-developers.com/t/unlock-root-twrp-unbrick-fire-tv-stick-2nd-gen-tank.3907002/page-2 , tank-only.)
- Full backup without TWRP: `adb shell su -c 'dd if=/dev/block/by-name/<name> of=/sdcard/...'` for raw partitions, or pull the `super` block device. Your device has root, so this is possible. Confirm block names with `ls -l /dev/block/by-name/` (not checked on your device). [U]
- Store off-device backups. Verify each image hash after pull. [U]

## 6. REA and reverse-engineering tooling

**REA (github.com/morluto/rea)** [S] https://github.com/morluto/rea
- Prerequisites: Node.js 22.19+, 24.11+, or 26+, and npm. [S]
- Agent setup: `npx rea-agents setup`, choose Claude Code, review and approve changes, restart the agent. Setup registers the MCP server and keeps backups. [S]
- CLI: `npm install --global rea-agents`, then `rea --help`. Update with `rea update`. [S]
- Ghidra: uses an existing installation. Raise the startup timeout with `REA_GHIDRA_STARTUP_TIMEOUT_MS` for large binaries. [S]
- Other env var: `REA_JEB_MCP_URL` (JEB). [S]
- Ghidra version and JDK: not stated on the README page. The install guide is at https://github.com/morluto/rea/blob/main/docs/installation.md and the tool catalog at https://github.com/morluto/rea/blob/main/docs/mcp-contracts.md (not fetched). [U] Check there before relying on `GHIDRA_INSTALL_DIR`. I did not confirm that variable.
- Operations (by target, from README): native binaries (pseudocode, asm, strings, symbols, xrefs); ELF; EVM bytecode; crash traces; JS/Electron; websites; HAR/mitmdump; .NET; **Android APKs (manifest, classes, decompiled methods, references)**; **Android devices over adb (packages, processes, logs, dumps, file transfer)**; firmware. The adb and APK paths match this project's needs.
- Note: REA is new (GitHub trending around 2026-10-08). [W] https://aitoolly.com/de/ai-news/article/2026-10-08-rea-surfaces-on-github-trending-leveraging-ai-agents-to-reverse-engineer-software-from-application-b

**Ghidra MCP alternatives** (if REA does not fit):
- GhidraMCP (LaurieWired): https://github.com/LaurieWired/GhidraMCP [W]
- ReVa (cyberkaida) Claude Code plugin: https://skillselion.com/plugin/cyberkaida/reverse-engineering-assistant [W]

**JADX (better fit for Amazon's Java code, per your note):**
- jadx-ai-mcp (Java plugin, v6.4.0, 2026-05-28, Apache-2.0, needs Java 11+) plus jadx-mcp-server (Python, 20+ tools). https://github.com/zinja-coder/jadx-ai-mcp (listed via https://dev.co/ai/mcp/jadx-mcp-server) [W]
- mobilehackinglab jadx-mcp-plugin with a FastMCP adapter: https://playbooks.com/mcp/mobilehackinglab-jadx-android-decompiler [W]
- Privacy: JADX-AI-MCP sends decompiled code to LLM endpoints. Relevant for Amazon proprietary code. [W]
- Avoid the shyft.ai `uvx pip install jadx-mcp-server` config; it is not a valid invocation. [W]

## 7. Package-dependency analysis for system images

- AOSP script "Find APK sharedUserId violators" in e/OS build tree: runs against product output, uses aapt/aapt2, checks system, vendor, product, system_ext. [W] https://gitlab.e.foundation/e/os/android_build/-/commit/101dc0e0d7f8f20b32238391cd446f8d16206e06
- Androguard (Python): manifest parsing, sharedUserId, permissions, dynamic loading. Best option for scripting checks over an extracted system. [W] (no URL fetched; see https://github.com/androguard/androguard)
- APKra: offline APK static analysis, small project. [W] https://github.com/UmutCanYY/APKra
- Exodus standalone: tracker detection, not a dependency tool. [W] https://github.com/Exodus-Privacy/exodus-standalone
- Shared libraries and intents are not covered by any of the tools above. Check them with `readelf -d` on .so files and by grepping `.rc` and `AndroidManifest.xml` for intent-filters. [U]

## Open items / next checks

1. Read the mantis and Sheldon XDA threads from a browser (403 to fetcher).
2. Confirm `karat` on twrp.me and in any Fire TV device list.
3. Check REA's docs/installation.md for Ghidra version and JDK.
4. Check whether your partitions are ext4 or EROFS (`file`).
5. Test vbmeta flags with a backup of your current vbmeta before any flash.
