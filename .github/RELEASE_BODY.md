# Armada-865 v0.3.1-beta

<!-- FORMAT RULE (project law): releases follow Keep a Changelog
     (keepachangelog.com). Structure: Highlights (2-4 human sentences), then
     Added / Changed / Fixed / Known issues — terse bullets, no essays.
     DOWNLOAD: single .img.gz hosted on Google Drive (NO GitHub split-zip
     assets). Paste the GDrive folder link under Download before publishing. -->

SteamOS-like Linux for Snapdragon 865 Retroid handhelds (Pocket 5 · Flip 2 ·
Mini V2). New here? Start with the
[setup guide](../../blob/sm8250/docs/setup-guide.md).

## Highlights

**SD card formatting now works.** Steam's own Format button formats and uses a
microSD as a game library, natively — the long-standing "format failed" error
is fixed at the kernel level.

## Fixed

- **microSD formatting** — the kernel now supports case-insensitive (casefold)
  ext4, so Steam's built-in formatter mounts the card it just created instead of
  reporting failure. Format a card in **Steam → Settings → Storage** and use it
  as a library.
- Build now tracks the current upstream gamescope session script (external
  package drift that had been blocking updates).

## Recap: v0.3.0-beta

Silent temperature-driven fans (RP5 & Mini V2), unified power modes (Quick
Access and Armada Control set the same mode + fan curve), and a ~78-commit
mainline sync (FEX 2607, per-game Proton selection, Armada Control settings
persistence).

---

## Download

**➡️ Get the image here: [Google Drive folder](GDRIVE_LINK_HERE)**

One file — `armada-<date>.img.gz`. No multi-part archives.

## Install (non-invasive — nothing written to your device)

1. Flash `armada-*.img.gz` to a 64 GB+ microSD with **balenaEtcher** or
   **Raspberry Pi Imager** (both take the `.img.gz` directly). Rufus users:
   decompress to `.img` first, use DD mode.
2. Insert the SD, power on **holding Volume Up** → boot menu → **Boot**. Armada
   auto-selects your device and boots to Steam. First boot takes a few minutes.
   Login: `armada` / `armada`.

Boot without the card (or without Vol+) and you're back in stock Android.

**Mini V2:** garbled pre-Linux boot screens? One-time fix:
`sudo armada-flash-loader` (Desktop Mode → Konsole) — details in the
[setup guide](../../blob/sm8250/docs/setup-guide.md).

## Updating

Already on Armada? **Steam Settings → System → Check for updates.** No
re-flash. Internal installs update the same way.

## Internal storage install (optional)

Boot from SD → Desktop Mode → **Armada Installer** → slider → install.
Android kept (factory-reset). Guide:
[docs/internal-install.md](../../blob/sm8250/docs/internal-install.md).
