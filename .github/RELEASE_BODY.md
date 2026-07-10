# Armada-865 — public beta

A SteamOS-like experience on Snapdragon 865 Retroid handhelds. See the
[README](../../tree/sm8250#readme) for the full story, what works, and how this
fork differs from upstream Armada.

**Supported devices:** Retroid Pocket 5 · Retroid Pocket Flip 2

## Install (fully non-invasive — nothing is written to your device)

1. **Reassemble the image if it's split:** download all `*.part` files, then:
   - Linux/macOS: `cat armada-*.part > armada.img.zip` (or the matching name)
   - Windows (PowerShell): `cmd /c copy /b "armada-*.part" armada.img.zip`
   Verify with `sha256sum -c SHA256SUMS` if you like.
2. Unzip if needed, then **flash the image** to a 64 GB+ microSD with
   balenaEtcher / Raspberry Pi Imager / `dd`. It auto-expands on first boot.
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
- Battery %, power profiles (QAM → Armada Control), Decky, rumble (Flip 2).

## Known issues / quirks

- Double-tap Home flashes the Steam menu briefly before the panel opens.
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
