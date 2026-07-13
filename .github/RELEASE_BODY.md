# Armada-865 v0.2.1-beta

A SteamOS-like experience on Snapdragon 865 (SM8250) Retroid handhelds. See the
[README](../../tree/sm8250#readme) for the full story, what works, and how this
fork differs from upstream Armada.

**Supported devices:** Retroid Pocket 5 · Retroid Pocket Flip 2 · Retroid Pocket Mini V2

> ⚠️ **Early community beta.** Expect bugs — and please report them.
>
> **Fixed in v0.2.1:** analog-stick calibration now applies automatically at boot
> (v0.2.0 required a manual re-apply after each boot).

---

## ✨ What's new in v0.2.0-beta

- **~16% more in-game FPS** — DXVK/wine helper threads are pinned off the slow
  cores onto the fast cluster (measured 53→60 fps on DMC4). Plus FEX Multiblock is
  now the profile default so per-game tuning is reliable.
- **Analog sticks fixed** — the stick range was mis-calibrated so full tilt only
  *walked*; characters now run correctly in all directions.
- **GPU hangs recover instead of hard-locking** — a game that trips the Adreno now
  recovers to Steam instead of black-screening the whole device (a `power/control`
  fix that lets the driver actually reset the GPU). *(New — see caveats.)*
- **More games launch** — games that play a startup movie/cutscene (e.g.
  *Warhammer 40,000: Boltgun*) used to hang on a black screen; a bundled `libbz2`
  compatibility fix lets Wine's media stack load. First run of a never-before-working
  title on this platform.
- **Retroid Pocket Mini V2 support** — the near-square 1080×1240 "smallest SteamOS
  handheld."
- **Install to internal storage (advanced, RP5)** — `armada-865-install-internal`
  copies Armada onto the RP5's internal UFS so it boots without the SD card, with
  much faster game loads. `armada-865-uninstall-internal` reverses it. Keeps Android
  (factory-reset). **No bootloader flashing.**
- **Quieter sleep** — the audio watchdog no longer thrashes during fake-suspend.

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
3. Insert the SD, reboot **holding Volume Up** → boot from SD → in GRUB pick
   **your device** (RP5 / Flip 2 / **Mini V2 is the 3rd entry**; wrong entry =
   black screen, reboot and pick again).
4. First boot takes a few minutes. Default login: `armada` / `armada`.

Boot without the card (or without Vol+) and you're back in stock Android.

## Advanced: run from internal storage (RP5)

Once booted from SD, `sudo /usr/libexec/armada/armada-865-install-internal`
repartitions internal UFS and installs Armada there so it boots without the SD
(much faster loads). **This factory-resets Android** and is RP5-validated only —
full walkthrough in
[`docs/internal-install.md`](../../tree/sm8250/docs/internal-install.md).

---

## Known issues / caveats

- **GPU auto-recovery is new this release** and still being validated — if a game
  hard-locks the screen and needs a reboot, please report it with the game + a
  `sudo dmesg | grep -iE 'adreno|gpu|gdsc'`.
- **Stick calibration** was measured on one RP5; Mini V2 / Flip 2 sticks may differ
  slightly (still far better than the previous walk-only default).
- **Sleep is still "fake-suspend"** (screen/input off, instant wake). True
  suspend-to-RAM is a work-in-progress kernel/DT port.
- **This image is unsigned** — fine for flashing to SD; OTA `bootc upgrade` won't
  verify it.
- **External USB drives** can drop off the bus under sustained load on the
  handheld's port — use a powered hub if you add one as a games library.
- A game may start **silent**: tap Home once (open/close the Steam menu) and audio
  kicks in. Tracked.
- Wi-Fi MAC address changes every boot (router reservations won't stick).
- Headphone jack and Bluetooth are not yet validated.
- Mini V2: the **bootloader/GRUB menus render garbled** (cosmetic — before Linux
  knows the panel); SteamOS itself displays correctly.

## Reporting issues

Open a GitHub issue with your device, this tag, and what happened — and if you can
SSH (`armada@<device-ip>`, off by default; enable via Armada Control or Desktop
mode), attach:

```
journalctl -t sm8250-audio -t sm8250-audio-monitor -t sm8250-audio-keepalive -b
sudo dmesg | grep -iE 'q6asm|q6adm|wsa88|adreno|gpu'
```

Credits: [virtudude/armada](https://github.com/virtudude/armada) (the distro),
[ROCKNIX](https://github.com/ROCKNIX/distribution) (SM8250 device support & kernel patches).
