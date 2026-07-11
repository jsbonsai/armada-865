# Armada-865 — public beta

A SteamOS-like experience on Snapdragon 865 Retroid handhelds. See the
[README](../../tree/sm8250#readme) for the full story, what works, and how this
fork differs from upstream Armada.

**Supported devices:** Retroid Pocket 5 · Retroid Pocket Flip 2

## Install (fully non-invasive — nothing is written to your device)

1. **Download every part** (`.split.zip` + `.z01`, `.z02`, …) into one folder,
   then open the **`.split.zip`** file with 7-Zip / Windows Explorer / macOS
   Archive Utility / `unzip` and extract — you'll get one `armada-*.img.gz`.
   (Verify downloads with `sha256sum -c SHA256SUMS` if you like.)
2. **Flash `armada-*.img.gz`** to a 64 GB+ microSD with **balenaEtcher or
   Raspberry Pi Imager** (both take the `.img.gz` directly — recommended).
   Rufus users: decompress to `.img` first and use its "DD Image" mode; do NOT
   use any partition-scheme/format options — the image contains its own GPT
   layout. It auto-expands on first boot.
3. Insert the SD, reboot **holding Volume Up** → boot from SD → in GRUB pick
   **your device** (wrong entry = black screen; reboot, pick again).
4. First boot takes a few minutes. Default login: `armada` / `armada`.

Boot without the card (or without Vol+) and you're back in stock Android.

## Highlights of this build

- **Audio self-heals**: kernel fix for the ADSP session-lifecycle bug + a
  watchdog; if sound ever drops it recovers within ~30 s.
- **Sleep/wake works** (power button; fake-suspend — instant resume).
- **Double-tap Home** opens the Steam quick-access menu on both devices (the
  Flip 2 has no dedicated Back button). The brief Steam-menu flicker on
  double-tap is cosmetic.
- **Flip 2 lid**: close to sleep, open to wake (validated).
- **Max performance**: set BOTH performance controls to Performance — the
  SteamOS performance side-panel AND Armada Control (QAM → Decky → Armada
  Control → Edit power profile).
- Battery %, power profiles (QAM → Armada Control), Decky, rumble (Flip 2).

## Known issues / quirks

- Double-tap Home flashes the Steam menu briefly before the panel opens.
- A game may start silent: tap Home once (open/close the Steam menu) and audio kicks in. Tracked.
- Wi-Fi MAC address changes every boot (router reservations won't stick).
- Headphone jack and Bluetooth are not yet validated.
- If the screen looks "dead" after boot: it may be the saved backlight level —
  tap the brightness keys.
- Suspend is "fake" by design (screen/input off, instant wake); the SoC can't
  do real suspend-to-RAM.

## Reporting issues

Open a GitHub issue with your device, this tag, what happened — and if you can
SSH (`armada@<device-ip>`), attach:

```
journalctl -t sm8250-audio -t sm8250-audio-monitor -t sm8250-audio-keepalive -b
sudo dmesg | grep -iE 'q6asm|q6adm|wsa88'
```

Credits: [virtudude/armada](https://github.com/virtudude/armada) (the distro),
[ROCKNIX](https://github.com/ROCKNIX/distribution) (SM8250 device support).
