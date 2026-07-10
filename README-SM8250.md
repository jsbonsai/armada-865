# Armada for Snapdragon 865 handhelds — Retroid Pocket 5 & Flip 2

**A SteamOS-like experience on SD865 Retroid handhelds.** This is a community
port of [Armada](https://github.com/virtudude/armada) — the Fedora-bootc-based,
SteamOS-style distro for ARM64 gaming handhelds — to **Snapdragon 865 (SM8250)**
devices:

- **Retroid Pocket 5** (primary, most tested)
- **Retroid Pocket Flip 2** (boots and plays; a few rough edges — see Known issues)

You get: Steam (native ARM64 client) with gamepad UI, Proton + FEX for x86/x64
Windows games, turnip/Vulkan on the Adreno 650, quick-access menu with TDP/power
profiles, Decky, and OTA-style image updates — on a $200-class handheld.

> ⚠️ **Status: early community beta.** It boots from microSD and does not touch
> your Android install, but treat it accordingly: expect bugs, report them, and
> don't put data on it you can't lose.

All credit for Armada itself goes to [virtudude](https://github.com/virtudude/armada);
device support builds on the SM8250 work in [ROCKNIX](https://github.com/ROCKNIX/distribution).
This port adds the SM8250 kernel/DTS/audio/input/power enablement on top.

---

## What works

| Area | Status |
|---|---|
| Boot (GRUB/EFI from microSD) | ✅ RP5 + Flip 2 (menu entry per device) |
| Display, brightness | ✅ |
| Controls (sticks, buttons, triggers) | ✅ deck-uhid; shows up as a SteamOS handheld |
| Steam quick-access panel (QAM) | ✅ RP5 (Back button) · 🔶 Flip 2 (in progress — fewer buttons) |
| Speakers | ✅ (see notes — this took four separate root-cause fixes) |
| Wi-Fi | ✅ (game mode; no desktop GUI applet yet) |
| Games (Proton/FEX) | ✅ Hades, Castle Crashers, DMC4, L4D2, MK9 tested |
| Power profiles (Eco/Balanced/Performance) | ✅ via QAM → Armada Control |
| Battery % in Steam | ✅ |
| Rumble | ✅ Flip 2 · 🔶 RP5 (validating) |
| Sleep/wake | 🔶 in progress (fake-suspend wiring) |
| Headphone jack | 🔶 untested |
| Bluetooth | 🔶 untested |
| Suspend-to-RAM | ❌ not planned (SoC limitation; fake-suspend instead, like other Armada devices) |

## Performance expectations (RP5, Performance profile)

- Hades: ~55–60 fps @ 720p, 40–55 fps @ 1080p
- 2000s/2010s-era titles (the sweet spot): generally great
- Expect roughly 40–50% of an SM8550 device in CPU, less in GPU

---

## Install

**You need:** a microSD card (64 GB+ recommended, A1/A2 class), a PC to flash
with, and your Retroid Pocket 5 or Flip 2.

1. Download the latest image from **[Releases](../../releases)**.
2. Flash it to the microSD with [balenaEtcher](https://etcher.balena.io/),
   Raspberry Pi Imager, or `dd`. (If the download is split into parts, join or
   unzip first — instructions in the release notes.)
3. Insert the card into the device. The image auto-expands to fill the card on
   first boot.

## Boot ritual (important — read this)

These devices boot **Android first** from internal storage. To boot Armada:

1. Power on (or reboot from Android).
2. **Hold Volume Up** during boot → you'll land in a boot menu (U-Boot).
3. Choose to boot from SD → **GRUB menu** appears.
4. Select **Retroid Pocket 5** or **Retroid Pocket Flip 2** (match your device —
   the wrong entry means a black screen; just reboot and pick again).
5. First boot takes a few minutes (filesystem expansion + Steam setup), then
   log into Steam.

Your Android install is untouched: power on without the SD card (or without
holding Vol+) and you're back in Android.

## Audio notes

Speaker audio on SM8250 was the hardest part of this port (a DSP session-lifecycle
kernel bug, a DAPM routing-order trap, amplifier power-management races, and an
AFE start race — details in the commit history). The shipped image includes a
kernel fix plus a self-healing watchdog: if audio ever drops, **it should recover
by itself within ~30 seconds.** If it doesn't, that's a bug we want — see
Reporting issues.

## Reporting issues

Open a GitHub issue with:

1. Device (RP5 / Flip 2) and image version (release tag).
2. What happened + what you expected.
3. If you can SSH (see below), attach:
   `journalctl -t sm8250-audio -t sm8250-audio-monitor -t sm8250-audio-keepalive -b`
   and `sudo dmesg | grep -iE 'q6asm|q6adm|wsa88'` for audio issues.

**SSH access:** the device answers at `ssh armada@<device-IP>` (find the IP in
Steam Settings → Internet), default password `armada`. **Change the password if
you keep SSH enabled.**

## Changes from upstream Armada (summary)

- **Kernel** ([armada-packages sm8250 branch](../../../armada-packages/tree/sm8250)):
  SM8250 DTS for RP5/Flip 2 (vendored from ROCKNIX), ~13 patch series (panel,
  gamepad, PMIC/battery/charger, haptics, display, q6asm audio), plus an original
  fix for a q6asm-dai session-lifecycle bug that killed audio on XRUN recovery.
  Battery fuel-gauge/charger drivers enabled.
- **Boot**: SM8250 boots via GRUB/EFI (raw kernel on the ESP), not the
  Android-bootimg path used by SM8550+; shutdown regeneration of the boot
  payload is GRUB-aware so it can't corrupt the kernel file.
- **Audio stack**: manual PipeWire sink on the WSA881x speaker path, WirePlumber
  auto-ALSA disabled for this card, SoundWire amp runtime-PM pinned, PCM held
  open by a silent keeper stream, and a watchdog that detects + heals the
  remaining failure modes.
- **Input**: Retroid gamepad InputPlumber profiles (deck-uhid), QAM button
  mapping.
- **Device model**: RP5/Flip 2 device profiles, SM8250 power/underclock tiers,
  MangoHud GPU patch.

## Building it yourself

This repo's `sm8250` branch is the OS image; kernel/mesa/etc. packages build in
[`armada-packages`](../../../armada-packages) (branch `sm8250`). GitHub Actions
build the container image on push; the flashable disk image is the manual
"Build disk image" workflow. See upstream Armada docs for the general build
architecture.

## Thanks

- [virtudude/armada](https://github.com/virtudude/armada) — the distro this is a port of
- [ROCKNIX](https://github.com/ROCKNIX/distribution) — SM8250 device trees, kernel patches, and the ABL bootloader chain
- The FEX, freedreno/turnip, and InputPlumber projects
