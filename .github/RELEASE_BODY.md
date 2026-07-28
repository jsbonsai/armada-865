# Armada-865 v0.3.0-beta

A SteamOS-like experience on Snapdragon 865 (SM8250) Retroid handhelds. See the
[README](../../tree/sm8250#readme) for the full story, what works, and how this
fork differs from upstream Armada.

**Supported devices:** Retroid Pocket 5 · Retroid Pocket Flip 2 · Retroid Pocket Mini V2

> ⚠️ **Early community beta.** Expect bugs — and please report them.

---

## ✨ What's new in v0.3.0-beta

### Fans that finally behave

Until now the fan on these devices ran at **one fixed speed, forever** — the
same constant ~20% hum whether the device was ice-cold idle or working hard at
82°C (it literally never ramped — a firmware table nobody was driving). This
release replaces that with a real temperature-driven fan system, tuned per
device from live telemetry:

- **Silent at idle** (Retroid Pocket 5 and Mini V2): below ~55–59°C the fan is
  **off**. Menus, the Steam home screen, video — silence.
- **One steady speed while gaming** — the curve holds a flat level across each
  device's measured in-game temperature band instead of hunting up and down.
- **Gradual, smooth transitions** — spin-up and spin-down are slew-limited;
  no sudden fan lurches.
- **Full cooling strength under heavy load** — at the hottest measured
  workloads (big downloads, 80°C+) cooling matches or exceeds the old behavior.
  Kernel thermal protection remains active underneath as an independent backstop.
- Flip 2 keeps the standard curves this release (its tuning pass is next).

### Power modes, unified (this was confusing before — read once)

**Eco / Balanced / Performance is now ONE mode with two buttons.** Pressing a
power mode in Steam's Quick Access menu and pressing one in the Armada Control
plugin now set the **same** underlying mode — whichever you pressed last wins.
Each mode is a bundle: CPU clocks + GPU behavior + **which fan curve runs**
(Eco = quietest/latest-spinning, Performance = earliest-spinning). Previously
the Quick Access buttons weren't connected to Armada's power system at all,
which made the two menus feel contradictory. Now: one mode, two doors.

### Mainline sync

This release folds in ~78 commits from upstream Armada: the new FEX 2607
emulation core, an updated Armada Control plugin (settings now persist
properly; per-game Proton selection), `-noshaders` (no background shader
processing — trades pre-warmed caches for zero background CPU burn), improved
power-button handling, and assorted fixes. **Known trade-off:** some games may
run a couple of FPS below the previous release with FEX 2607 (per-game FEX
version selection is in development); first runs of a game may stutter briefly
while caches rebuild, then smooth out.

## Recap: v0.2.x highlights

- **OTA updates are live** — Armada now updates itself: **Steam Settings →
  System → Check for updates**, exactly like a Steam Deck. No more re-flashing
  the SD for every fix. Images are cryptographically signed and verified on-device.
- **Mini V2 garbled boot menus: actually fixed** — the scrambled U-Boot/GRUB
  screens turn out to be a faulty bootloader build shipped by a Retroid Android
  OTA. Once booted into Armada, run `sudo armada-flash-loader` — it flashes
  [Retroid's official fixed U-Boot](https://github.com/RetroidPocket/u-boot/releases/tag/rp-v1.0.1)
  (with backup and verification; nothing else on the device is touched) and every
  boot screen renders correctly from then on.
- **Boots straight through** — each device now auto-selects its own boot entry;
  no more navigating a GRUB menu or black screens from picking the wrong device.
- **Cleaner downloads** — the image now extracts with its proper
  `armada-*.img` name (it used to come out as a confusing `disk.raw`).

### Recap: what v0.2.0/v0.2.1 brought

~16% more in-game FPS (helper threads pinned to fast cores) · analog-stick
calibration fixed and applied at every boot · GPU hangs recover instead of
hard-locking · startup-movie games (e.g. *Boltgun*) now launch · Retroid Pocket
Mini V2 support · install-to-internal-storage for the RP5 · FEX Multiblock
default · quieter fake-suspend.

---

## Install (fully non-invasive — nothing is written to your device)

1. **Download every part** (`.split.zip` + `.z01`, `.z02`, …) into one folder,
   then open the **`.split.zip`** file with 7-Zip / Windows Explorer / macOS
   Archive Utility / `unzip` and extract — you'll get one `armada-*.img.gz`.
   (Verify with `sha256sum -c SHA256SUMS` if you like.)
2. **Flash `armada-*.img.gz`** to a 64 GB+ microSD with **balenaEtcher or
   Raspberry Pi Imager** (both take the `.img.gz` directly — recommended).
   Rufus users: decompress to `.img` first and use its "DD Image" mode; do NOT
   use any partition-scheme/format options — the image contains its own GPT
   layout. It auto-expands on first boot.
3. Insert the SD, reboot **holding Volume Up** → boot from SD → Armada boots
   straight through to SteamOS (it auto-detects your device; hold any key
   during the 1-second window if you ever want the boot menu).
4. First boot takes a few minutes. Default login: `armada` / `armada`.

Boot without the card (or without Vol+) and you're back in stock Android.

> **Mini V2:** if your pre-Linux boot screens render garbled, run
> `sudo armada-flash-loader` once from Desktop Mode (Konsole) — see "What's new"
> above. Also do the one-time UI scale fix: **Settings → Display →** turn off
> *Automatically Scale Interface*, set the slider to ~50%.

## Updating from any earlier release

Flash this image once — from now on, **Steam Settings → System → Check for
updates** keeps you current (no SD re-flash). RP5 internal-storage installs
update the same way.

## Advanced: run from internal storage (RP5)

Once booted from SD, `sudo /usr/libexec/armada/armada-865-install-internal`
repartitions internal UFS and installs Armada there so it boots without the SD
(much faster loads). **This factory-resets Android** and is RP5-validated only —
full walkthrough in
[`docs/internal-install.md`](../../tree/sm8250/docs/internal-install.md).

---

## Known issues / caveats

- **`armada-flash-loader` is new this release** — it backs up your current
  bootloader and verifies after writing, but if anything looks wrong, stop and
  report before rebooting (recovery is always possible via fastboot).
- **GPU auto-recovery** is still being validated — if a game hard-locks the
  screen and needs a reboot, please report it with the game + a
  `sudo dmesg | grep -iE 'adreno|gpu|gdsc'`.
- **Stick calibration** was measured on one RP5; Mini V2 / Flip 2 sticks may
  differ slightly (still far better than the old walk-only default).
- **Sleep is still "fake-suspend"** (screen/input off, instant wake). True
  suspend-to-RAM is a work-in-progress.
- **External USB drives** can drop off the bus under sustained load on the
  handheld's port — use a powered hub if you add one as a games library.
