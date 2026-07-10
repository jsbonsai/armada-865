# Armada-865

**A Snapdragon 865 (SM8250)–specific fork of [Armada](https://github.com/virtudude/armada)**
— the SteamOS-like Linux distribution for ARM handhelds built on Fedora bootc —
ported to and maintained for:

| Device | Status |
|---|---|
| **Retroid Pocket 5** | ✅ Primary target, most tested |
| **Retroid Pocket Flip 2** | ✅ Boots & plays; minor papercuts (see below) |
| Retroid Pocket Mini / Mini v2 | 🔜 Planned (same SoC; device trees exist in ROCKNIX) |

Upstream Armada targets SM8550/SM8650/SM8750 devices. This fork exists because
SM8250 needs its own kernel enablement, a **different boot architecture**, and a
substantially different audio bring-up — all documented below.

What you get: native ARM64 Steam with the gamepad UI, CachyOS Proton + FEX for
x86/Windows games, Vulkan via freedreno/turnip on the Adreno 650, power profiles
in the quick-access menu, Decky — with Android left intact on internal storage.

> ⚠️ **Early community beta.** Expect bugs — and please report them.
>
> **Completely non-invasive:** runs entirely from microSD using the **stock
> Retroid bootloader's boot menu** — no bootloader flashing, no root, nothing
> written to the device. Remove the SD card and it's exactly the phone-stock
> handheld it was.
>
> **Default credentials:** user `armada`, password `armada`. If you enable SSH,
> change the password.

---

## Install

You need: a 64 GB+ microSD (A2 class recommended), a PC to flash it, and your
RP5 / Flip 2.

**1. Flash the Armada-865 image to the SD card.**
Download from **[Releases](../../releases)**, flash with balenaEtcher /
Raspberry Pi Imager / `dd`. The image auto-expands to fill the card on first
boot. (If the release is split into parts, joining instructions are in the
release notes.)

**2. Boot Armada.**

- Insert the SD card and reboot **holding Volume Up** → the stock boot menu
  appears → boot from SD → **GRUB menu**.
- Select **your device** (RP5 or Flip 2 — the wrong entry means a black screen;
  just reboot and pick again).
- First boot takes a few minutes (filesystem expansion, Steam setup).

Boot without the SD (or without holding Vol+) and you're in stock Android as
always. (The image also carries a `rocknix_abl` folder inherited from upstream's
AYN/AYANEO install flow — **Retroid SM8250 devices don't need it**; ignore it.)

## What works

Controls (presents as a SteamOS handheld), display + brightness, speakers
(self-healing — see the audio section), Wi-Fi, battery status,
Eco/Balanced/Performance power profiles (QAM → Armada Control), Decky, games via
Proton/FEX — tested: Hades, Castle Crashers, DMC4, L4D2, MK9. Rumble works on
Flip 2. Ballpark: Hades ~55–60 fps @ 720p on Performance; 2000s/2010s titles are
the sweet spot (figure ~40–50% of an SM8550 device's CPU).

**In progress:** sleep/wake (fake-suspend), Flip 2 quick-access button (it has
one fewer button than the RP5), headphone jack & Bluetooth validation, RP5
rumble.

---

## How this fork differs from upstream Armada

### Boot architecture (the biggest structural change)

Upstream SM8550+ devices boot via the ABL directly loading an Android boot image
from `/KERNEL` on the SD card. **The SM8250 ABL chain doesn't support that
path** — here the chain is `ABL → U-Boot → EFI → GRUB`, so this fork boots via
**GRUB/EFI**: a GRUB binary + menu on the ESP, a **raw ARM64 kernel** at
`/KERNEL`, initramfs at `/INITRD`, per-device DTBs selected in the GRUB menu.
The shutdown-time boot-payload regeneration (`armada-bootimg-sync`) is
overridden to be GRUB-only on SM8250 — the upstream writer would overwrite
`/KERNEL` with an Android bootimg and break boot (learned the hard way, about a
dozen SD-card rescues' worth).

### Kernel ([`armada-packages`](https://github.com/jsbonsai/armada-packages/tree/sm8250) branch `sm8250`)

- RP5 / Flip 2 device trees vendored from ROCKNIX, built on Armada's unified kernel.
- ~13 ROCKNIX SM8250 patches: Retroid UART-MCU gamepad (+ force feedback),
  ICNA35XX/CH13726A panels, PM8150B PMIC, SPMI haptics, display fixes, q6asm
  period sizing, WSA881x shared powerdown GPIO, headphone jack detection.
- PM8150B **battery fuel-gauge and charger drivers enabled** (the drivers were
  in the patch set but never switched on — no battery % without this).
- **Original fix (`0812`)**: the q6asm-dai driver leaked its ADSP session on
  stop→prepare cycles (e.g. XRUN recovery during game-launch CPU spikes),
  permanently killing audio until reboot (`Buffer already allocated`, DSP error
  9). This fork tracks session state and tears stale sessions down on
  re-prepare. Candidate for upstreaming to ROCKNIX/mainline.

### Audio (the war story)

SM8250 uses the older q6asm ADSP framework (not AudioReach like SM8550+), and
the speaker path — WSA881x amplifiers on SoundWire — failed four independent
ways. This fork ships, in order of discovery:

1. **Correct DAPM routing order** — the two CODEC-DMA mixer controls knock each
   other off; the playback route must be set last.
2. **The kernel session-lifecycle fix** above.
3. **Amplifier runtime-PM pinning** — the amps intermittently fail
   wake-from-clock-stop on the SoundWire bus and go silently dead with zero DSP
   errors; a udev rule keeps them out of runtime suspend.
4. **A held-open PCM + watchdog** — a permanent inaudible stream prevents the
   stop→start transitions that lose an AFE/SoundWire start race (DMA arms but
   never clocks), and a 30-second watchdog detects every observed failure
   signature (frozen `hw_ptr`, PipeWire/kernel state mismatch, error storms)
   and recovers automatically.

Net effect: if audio ever drops, it heals itself within ~30 seconds. The whole
lifecycle is instrumented — `journalctl -t sm8250-audio -t sm8250-audio-monitor
-t sm8250-audio-keepalive` narrates it, and that's what bug reports should
attach. Also: WirePlumber auto-ALSA is disabled for this card, the sink is
created manually on the speaker PCM, and the PipeWire graph is pinned to 48 kHz
with a raised minimum quantum.

### Input

- InputPlumber profiles for the Retroid gamepad (UART MCU) presenting as a
  **deck-uhid** SteamOS handheld controller.
- Quick-access menu on the RP5's Back button (`BTN_BACK → QuickAccess`).
- Flip 2 (one fewer button): double-press-Home QAM in progress.

### Device model & power

- RP5 / Flip 2 device profiles (panel orientation, rotation shader, GPU floor).
- SM8250 power tiers are **underclock-only** (Eco/Balanced/Performance — no
  overclocking), selectable from the QAM.
- MangoHud patched for the Adreno 650.
- SoC-specific udev/PM rules per the audio section.

### Build & release

Same CI shape as upstream (container image on push → manual disk-image build),
with kernel/MangoHud package digests pinned to `armada-packages` branch
`sm8250`. `/etc/armada/` carries the bring-up scripts, made executable and
enabled at image build.

---

## Reporting issues

Open a GitHub issue with device, image version, what happened — and if you can
SSH (`armada@<device-ip>`; IP shown in Steam's network settings), attach:

```
journalctl -t sm8250-audio -t sm8250-audio-monitor -t sm8250-audio-keepalive -b
sudo dmesg | grep -iE 'q6asm|q6adm|wsa88'
```

## Building it yourself

This repo (branch `sm8250`) is the OS image; packages build in
[`armada-packages`](https://github.com/jsbonsai/armada-packages/tree/sm8250).
Push → container CI; the "Build disk image" workflow produces the flashable
`.img`. See upstream Armada for the general build architecture.

## Credits

- **[virtudude/armada](https://github.com/virtudude/armada)** — the distro this
  forks; all the distro-level work is theirs.
- **[ROCKNIX](https://github.com/ROCKNIX/distribution)** — SM8250 device trees,
  the kernel patch set, and the signed ABL chain.
- FEX-Emu, Mesa/freedreno, InputPlumber, gamescope, and the CachyOS Proton builds.
