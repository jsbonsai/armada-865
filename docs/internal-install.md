# Install Armada to internal storage (keeps Android) — user guide

**Status:** validated on hardware (RP5, 2026-07-11). This turns the running
SD-card Armada into a full internal install so the RP5 boots from its own UFS
storage with the SD card removed.

---

## What this does (ELI5)

Right now Armada runs from the SD card. This copies Armada onto the RP5's own
internal storage so games load from the fast built-in chip instead of the SD
card (measured ~60% faster loads; internal UFS is far faster at the random reads
games do). Afterwards you can pull the SD card out and the RP5 still boots
Armada.

It does **not** replace Android. Android stays installed but is **factory-reset**
(you lose Android apps and their data — the Android system itself is kept). It
shrinks Android's storage to make room for Armada.

**No bootloader flashing.** Unlike most "Linux on a handheld" guides, this writes
**nothing** to the bootloader (no XBL/ABL/EDL). The RP5's stock firmware already
knows how to boot our internal boot partition — we proved it on hardware
(`efibootmgr` showed the firmware booting internal UFS, `BootCurrent = scsi0`).
That is what makes this safe and reversible: the worst case is "put the SD card
back and boot from it."

---

## Prerequisites

- An RP5 **already running Armada from the SD card** (this is the normal Armada
  SD image). Do this on your "sacrificial"/primary Armada RP5.
- You are booted from the **SD card**, not from internal storage. The installer
  refuses to run if you booted internal.
- Root/SSH access to the device (`armada@rp5.local`, then `sudo`).
- The device plugged into power. The installer blocks sleep during the run, but
  don't fight it.
- Nothing important left in Android — it will be factory-reset.

No PC, no EDL cable, and no firmware download are required for the install
itself. (A PC-based EDL recovery kit is only ever relevant if you separately
choose to flash a bootloader — this installer never does.)

---

## Run it

SSH in (or open a terminal) and run, as root:

```bash
sudo /usr/libexec/armada/armada-install-internal
```

### Choosing the storage split

By default Android keeps **~20 GiB** and Armada gets the rest. To choose the
split, pass exactly one of:

```bash
# Give Android 32 GiB, Armada gets the rest:
sudo /usr/libexec/armada/armada-install-internal --android-size 32

# Or size Armada directly (Android keeps the remainder):
sudo /usr/libexec/armada/armada-install-internal --armada-size 90
```

Add `--yes` to skip the confirmation prompt (useful over a flaky SSH link):

```bash
sudo /usr/libexec/armada/armada-install-internal --android-size 32 --yes
```

Full options: `armada-install-internal --help`.

### What you'll see

1. A safety check ("Booted from … — OK") and a printed **plan** showing the exact
   MiB ranges for Android, `ARMADA_ESP`, and `ARMADA_ROOT`.
2. A confirmation prompt (unless `--yes`).
3. `GPT backed up to: /root/armada-gpt-backup-<timestamp>.bin` — the installer
   **always** backs up the partition table first, and prints the one-line command
   to restore it.
4. Progress steps: partitioning → staging the ESP → formatting root → ostree
   deploy → writing boot config → regenerating the ESP → a self-verify.
5. `Install complete.`

The whole thing takes a few minutes.

---

## After it finishes

1. **Power off.**
2. **Remove the SD card.**
3. **Power on**, and **hold Vol+** through the Android splash to reach the GRUB
   menu — it boots Armada from internal storage.

You now have:

- **Armada** running from internal UFS (faster game loads), and
- **Android**, factory-reset, on its (now smaller) partition — reachable by
  powering on **without** holding Vol+ (or with the internal Armada removed).

OTA updates (`bootc upgrade`) keep working on the internal install: the installer
copies the signed image origin across. (If you built Armada locally rather than
pulling the signed ghcr image, it prints a warning that OTA won't verify — that's
expected for local builds.)

---

## Reinstall / try again

Want to redo the install (e.g. to pick a different split, or after a bad run)?
Remove the internal install first, then run the installer again — the installer
refuses to run on top of an existing internal Armada install.

```bash
# From the SD system: remove Armada's partitions but leave the freed space empty…
sudo /usr/libexec/armada/armada-uninstall-internal --keep-free
# …then reinstall (it reclaims the freed tail automatically):
sudo /usr/libexec/armada/armada-install-internal --armada-size 90
```

> `--keep-free` skips growing Android back, so the reinstall is quick — the
> installer just re-shrinks/reuses the tail.

## Undo — give the space back to Android

To fully back out and return the internal storage to a stock-sized Android:

```bash
# From the SD system (this is the default mode):
sudo /usr/libexec/armada/armada-uninstall-internal
```

This deletes `ARMADA_ESP` + `ARMADA_ROOT`, grows Android `userdata` back over the
whole disk, and wipes it so **Android reformats it full-size on next boot**. Then
power on **without** Vol+ to boot Android (it re-initialises storage).

> ⚠️ **`armada-uninstall-internal` is newer than the installer and not yet as
> thoroughly hardware-validated** — it backs up the GPT first (so a bad run is
> recoverable with `--load-backup`), but treat it as beta until it has been
> exercised end-to-end.

## Rollback / recovery (manual)

Nothing here touches the bootloader, `xbl`, `abl`, `boot`, `super`, or `vbmeta`,
so there is **no brick path** to recover from — only "undo." In order of ease:

1. **Just use the SD card again.** Re-insert it and boot it (hold Vol+ and pick
   the SD entry, or simply leave the SD in). The SD is never modified and boots
   exactly as before. Internal changes don't impede SD boot.
2. **Restore the partition table by hand.** The installer printed a GPT backup
   path. From the SD system:
   ```bash
   sudo sgdisk --load-backup=/root/armada-gpt-backup-<timestamp>.bin /dev/sda
   ```
   (Restores only the partition *table*; a shrunk/removed filesystem is not
   re-grown by this.)

Android is factory-reset by the install regardless; that part is not "undone" by
rollback (its data was already gone).

---

## Notes / limitations

- **RP5 only, for now.** The no-flash internal boot was proven specifically on the
  Retroid Pocket 5 (SM8250). Other SM8250 units may differ; don't assume.
- The installer refuses to run if it finds an existing internal Armada/ROCKNIX
  install (`ARMADA_ESP`/`ARMADA_ROOT`/`ROCKNIX`/…). Remove it first with
  `armada-uninstall-internal --keep-free` (see "Reinstall / try again" above).
- It requires that Android `userdata` is the last partition on the internal disk
  (the stock RP5 layout) and refuses otherwise.
- It writes a GPT backup to `/root/` on the SD system — copy it somewhere safe if
  you want off-device insurance.
