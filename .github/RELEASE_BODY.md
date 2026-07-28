# Armada-865 v0.3.0-beta

<!-- FORMAT RULE (project law): releases follow Keep a Changelog
     (keepachangelog.com). Structure: Highlights (2-4 human sentences), then
     Added / Changed / Fixed / Known issues — terse bullets, no essays.
     Install/update boilerplate stays at the bottom and rarely changes. -->

SteamOS-like Linux for Snapdragon 865 Retroid handhelds (Pocket 5 · Flip 2 ·
Mini V2). New here? Start with the
[setup guide](../../blob/sm8250/docs/setup-guide.md).

## Highlights

The fan finally behaves: **silent at idle, one steady speed in games** (RP5 &
Mini V2), driven by real temperatures instead of the old single fixed speed.
Power modes are **unified** — Quick Access and Armada Control now set the same
mode, which also selects the fan curve. Plus ~78 commits synced from mainline
Armada.

## Added

- Per-device fan curves (RP5, Mini V2): fan off below ~55–59 °C, flat plateau
  across each device's measured gaming band, full cooling strength ≥ 80 °C.
- Per-game Proton version selection in Armada Control (from mainline).
- `-noshaders`: no background shader processing burning CPU after downloads.

## Changed

- **Power modes unified**: Eco/Balanced/Performance is one mode with two
  buttons (Quick Access ⟷ Armada Control — last press wins); each mode bundles
  CPU clocks + GPU behavior + fan curve. Previously Quick Access wasn't
  connected to Armada's power system at all.
- FEX emulation core updated to 2607 (mainline). **Trade-off:** some titles run
  a few FPS below v0.2.x; per-game FEX version selection is in development.
- Mainline sync (~78 commits): improved power-button handling, fan keeps
  running during fake-sleep when warm, assorted fixes.

## Fixed

- Armada Control settings now persist across reboots (mainline rework).
- Staged OTA updates can no longer be silently dropped at shutdown.
- Fan no longer hums at ~20 % duty forever at cool idle (RP5, Mini V2).

## Known issues

- Occasional silent game launch — tap **Home** once and audio kicks in.
- First run of a game may stutter while caches rebuild, then smooths out.
- Flip 2 keeps factory fan curves this release (tuning pass is next).
- Headphone jack / Bluetooth audio not yet validated.
- Sleep remains "fake-suspend" (instant wake); true S3 is an open problem on
  SM8250 everywhere.

---

## Install (non-invasive — nothing written to your device)

1. Download **every part** (`.split.zip` + `.z01`…) into one folder, extract
   the `.split.zip` → you get `armada-*.img.gz`. (Single `.img.gz` release?
   Skip extraction.)
2. Flash `armada-*.img.gz` to a 64 GB+ microSD (balenaEtcher / Raspberry Pi
   Imager take it directly; Rufus: decompress first, DD mode).
3. Insert SD, power on **holding Volume Up** → boot menu → **Boot**. Armada
   auto-selects your device. First boot takes a few minutes.
   Login: `armada` / `armada`.

Boot without the card (or without Vol+) and you're back in Android.

**Mini V2:** garbled pre-Linux boot screens? One-time fix:
`sudo armada-flash-loader` (Desktop Mode → Konsole) — details in the
[setup guide](../../blob/sm8250/docs/setup-guide.md).

## Updating

Already on Armada? **Steam Settings → System → Check for updates.** No
re-flash, ever. Internal installs update the same way.

## Internal storage install (optional)

Boot from SD → Desktop Mode → **Armada Installer** → slider → install.
Android kept (factory-reset). Guide:
[docs/internal-install.md](../../blob/sm8250/docs/internal-install.md).
