# Armada-865

**A Snapdragon 865 (SM8250) fork of [Armada](https://github.com/virtudude/armada)** —
the SteamOS-like Linux distribution for ARM handhelds, built on Fedora bootc —
ported to and maintained for the Retroid Pocket SM8250 family.

| Device | Status |
|---|---|
| **Retroid Pocket 5** | ✅ Primary target, most tested |
| **Retroid Pocket Flip 2** | ✅ Boots & plays (lid sleep/wake works; fan tuning pass pending) |
| **Retroid Pocket Mini V2** | ✅ Fully supported — the near-square 1080×1240 "smallest SteamOS handheld" |
| Retroid Pocket Mini (v1) | 🔜 Planned |

> ⚠️ **Early community beta.** Expect bugs — and please [report them](#reporting-issues).
>
> **Non-invasive by default:** runs entirely from microSD via the stock Retroid
> boot menu — no bootloader flashing, no root. Remove the SD and the device is
> stock again. Default login: `armada` / `armada` (change it if you enable SSH).

## Features

- **Native ARM64 Steam** with the full gamepad UI; **CachyOS Proton + FEX** for
  x86/Windows games; Vulkan via freedreno/turnip on the Adreno 650; Decky.
- **Over-the-air updates** — after one flash, the OS updates itself from
  *Steam Settings → System → Check for updates*, like a Steam Deck. Images are
  cryptographically signed and verified on-device.
- **Graphical internal-storage installer** — install to internal UFS (keeping
  Android) from a desktop app with a storage slider; reinstall and full
  uninstall included.
- **Tuned thermals** — the fan is *off* at cool idle and holds one steady speed
  in games (RP5 & Mini V2; temperature-driven with kernel failsafes beneath).
- **One power mode, everywhere** — Eco/Balanced/Performance set from either the
  Quick Access menu or Armada Control control the same thing: CPU/GPU behavior
  *and* the fan curve. Last press wins.
- **Performance & compatibility handled for you** — game helper threads pinned
  to fast cores, GPU hang auto-recovery, per-device input calibration, startup-
  movie titles fixed, Mini V2 UI scale set automatically on first boot.

## Quick start

1. Download all parts from the [latest release](../../releases/latest), extract
   the `.split.zip`, and flash the `armada-*.img.gz` to a 64 GB+ microSD with
   balenaEtcher or Raspberry Pi Imager.
2. Insert the SD and power on **holding Volume Up** → boot menu → **Boot**.
   Armada auto-selects your device and boots straight to Steam.
3. Sign in and play. First boot takes a few minutes.

Full walkthrough (including per-device notes and recovery):
**[docs/setup-guide.md](docs/setup-guide.md)**

**Mini V2 owners:** if pre-Linux boot screens look garbled, run
`sudo armada-flash-loader` once — it installs
[Retroid's official fixed bootloader](https://github.com/RetroidPocket/u-boot/releases/tag/rp-v1.0.1)
(with backup). Explanation in the setup guide.

## Updating

You never re-flash. **Steam Settings → System → Check for updates.** Internal
installs update the same way.

## Install to internal storage (optional)

Boot from SD → Desktop Mode → **Armada Installer** → choose Android's share of
storage → install. Android is kept but factory-reset; games load much faster
from internal. Reinstall/uninstall from the same app. Validated on RP5 and
Mini V2. Details: [docs/internal-install.md](docs/internal-install.md).

## What works & performance

Controls, display + brightness, speakers, Wi-Fi, battery, rumble (RP5 & Flip 2),
sleep/wake (short-press power; Flip 2 lid), power profiles, Decky, OTA updates.

Tested games include Hades, DMC4, Castle Crashers, L4D2, MK9, Boltgun.
Ballpark: Hades ~55–60 fps @ 720p, DMC4 ~55–60 fps on Performance; 2000s/2010s
titles are the sweet spot (~40–50 % of an SM8550 device's CPU).

**Quick Access menu:** RP5 — press **Back** or double-tap **Home**; Flip 2 /
Mini V2 — double-tap **Home**.

## Known issues

- Silent game launch occasionally: tap **Home** once (open/close Steam menu)
  and audio kicks in. Tracked.
- Some titles run a few FPS below the previous release on the new FEX 2607
  core; per-game FEX version selection is in development.
- First run of a game may stutter briefly while caches build, then smooths out.
- Headphone jack and Bluetooth audio not yet validated.
- Sleep is "fake-suspend" (screen/input off, instant wake) — true
  suspend-to-RAM remains an open problem on SM8250 for every distro.

## How this fork differs from upstream

Upstream Armada targets SM8550/SM8650/SM8750. SM8250 needed its own:

- **Boot architecture** — GRUB/EFI via the stock Retroid U-Boot chain (upstream
  uses an Android-bootimg path); per-device DTB auto-selection; no bootloader
  flash on Retroid hardware.
- **Kernel enablement** — SM8250 device trees (incl. our Mini V2 port), panel,
  input, battery, and audio patches; see
  [armada-packages](https://github.com/jsbonsai/armada-packages/tree/sm8250).
- **Audio bring-up** — the SM8250's legacy ADSP audio stack required extensive
  kernel and userspace work (a self-healing pipeline with watchdogs). The full
  engineering story lives in the repo history; the short version is: it works,
  and it repairs itself if the DSP misbehaves.
- **Fan control tuning**, per-device power profiles, input calibration, and the
  internal-install tooling for this hardware generation.

## Reporting issues

Run `sudo armada-report` in Desktop Mode (Konsole) — it bundles logs (no
secrets) into a tar.gz on the Desktop. Open a
[GitHub issue](../../issues/new/choose) with your device, version
(Steam Settings → System), and the archive attached.

## Building it yourself

CI builds everything: pushes to `sm8250` build and sign the OS container;
`build-disk.yml` produces the flashable image; `release.yml` publishes it.
Local builds: `just build-armada-image` on an ARM64 Linux host.

## Credits

Built on [Armada](https://github.com/virtudude/armada) by virtudude, the
[ROCKNIX](https://rocknix.org) project's SM8250 kernel enablement,
[Retroid's U-Boot](https://github.com/RetroidPocket/u-boot), FEX-Emu, CachyOS
Proton, and the freedreno/turnip Mesa stack. Thank you all.
