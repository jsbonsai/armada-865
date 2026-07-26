# Armada-865 Setup Guide

Welcome! This guide takes you from "I just downloaded a zip file" to playing
Steam games on your Retroid handheld — no Linux experience needed. Every step is
spelled out, and anything risky has a big warning in front of it.

**Supported devices:** Retroid Pocket 5 · Retroid Pocket Flip 2 · Retroid
Pocket Mini V2

> ⚠️ **Early community beta.** Things mostly work great, but expect the
> occasional bug — and please [report them](#reporting-a-bug) so we can fix them.

**The most important thing to know:** the standard Armada setup is **completely
non-invasive**. It runs entirely from a microSD card using your device's
built-in boot menu. Nothing is flashed, nothing is rooted, nothing on your
device is modified. Pull the SD card out and your handheld is exactly the stock
Android device it was. (There *is* an optional internal-storage install later in
this guide — that one **is** invasive, and it's clearly marked.)

---

## 1. What you need

- **A supported Retroid handheld** (RP5, Flip 2, or Mini V2).
- **A microSD card, 64 GB or larger.** An "A2"-rated card (it says A2 on the
  label) is strongly recommended — game load times depend heavily on card speed.
- **A PC or Mac** with an SD card reader, to flash the card.
- **A Steam account** (free — the same one you'd use on a PC or Steam Deck).
- **Wi-Fi**, for signing in to Steam and downloading games.

About 30 minutes, most of it waiting for the flash to finish.

---

## 2. Download the release

1. Go to the project's **Releases** page on GitHub and open the latest release.
2. GitHub limits how big a single file can be, so the image is **split into
   parts**: one file ending in **`.split.zip`** plus numbered parts ending in
   **`.z01`**, **`.z02`**, and so on. **Download every part into the same
   folder.** If even one part is missing, extraction will fail.
3. Open the **`.split.zip`** file (that one, not the `.z01`) with:
   - **Windows:** 7-Zip (free) or Windows Explorer
   - **macOS:** double-click it (Archive Utility)
   - **Linux:** `unzip`
4. Extracting gives you a single file named like **`armada-<version>.img.gz`**.
   That's your disk image — you're ready to flash.

> **Optional integrity check:** the release includes a `SHA256SUMS` file. If a
> download seems corrupted, run `sha256sum -c SHA256SUMS` (Linux/macOS) next to
> the downloaded files to verify them.

---

## 3. Flash the SD card

> ⚠️ **Flashing erases everything on the SD card.** Double-check you selected
> the SD card and not another drive.

Pick whichever tool you like — all three work:

**balenaEtcher (easiest, Windows/Mac/Linux)**
1. Open Etcher → **Flash from file** → pick the `armada-*.img.gz` (no need to
   unzip it further — Etcher handles `.img.gz` directly).
2. **Select target** → your SD card.
3. **Flash!** and wait. Etcher verifies automatically when done.

**Raspberry Pi Imager (Windows/Mac/Linux)**
1. **Choose OS → Use custom** → pick the `armada-*.img.gz` (also taken
   directly).
2. **Choose storage** → your SD card → **Write**.
3. If it offers any "OS customisation" options, choose **No** — the image needs
   no tweaking.

**Rufus (Windows)**
1. First decompress `armada-*.img.gz` to a plain `armada-*.img` (7-Zip can do
   this).
2. In Rufus, select the SD card, select the `.img`, and make sure it's writing
   in **"DD Image" mode**.
3. **Do not** touch any partition-scheme or file-system options — the image
   contains its own complete disk layout.

When the flash finishes, your computer may complain the card is "unreadable" or
ask to format it — **that's normal** (your OS just doesn't recognise Linux
partitions). Click cancel/eject and take the card out. The image automatically
expands to fill your whole card on first boot, so a 256 GB card gives you
256 GB of game space.

---

## 4. First boot

The ritual is the same on all three devices:

1. **Power the device off** completely.
2. **Insert the SD card.**
3. **Press and hold Volume Up (Vol+), then press Power** — and **keep holding
   Vol+** through the Retroid logo.
4. The **stock Retroid boot menu** appears (this menu is built into every
   Retroid device — Armada didn't put it there and doesn't change it).
5. Select **Boot** — that's the entry that boots from the SD card. Use the
   volume keys or touch to navigate, depending on your device.
6. Armada boots straight through to the Steam interface. It auto-detects which
   device you have — you don't need to pick anything. (If you're curious: there
   is a 1-second boot-menu window where holding any key shows the advanced GRUB
   menu. You'll likely never need it.)

**The first boot takes a few minutes** — the system is expanding the filesystem
to fill your card and setting up Steam. Later boots are much faster. Just let
it sit until the Steam screen appears.

**To get back to Android at any time:** power off, then power on *without*
holding Vol+ (or with the SD card removed). Android is untouched and boots
exactly as before. You can switch back and forth forever.

> **Default login:** if anything ever asks for a username or password (Desktop
> Mode, for example), it's user **`armada`**, password **`armada`**.

### Mini V2 owners: why do the boot screens look garbled?

On some Mini V2 units, the very first screens *before* Linux starts — the boot
menu and the brief GRUB screen — appear **scrambled/garbled**. Don't panic, and
don't power off:

- **Your device is fine and Armada still boots perfectly through it.** The
  garbled part is purely cosmetic.
- **Why it happens:** a Retroid Android system update (OTA) shipped a faulty
  build of the low-level bootloader's display code. It came from Retroid, not
  from Armada — you'd see the same garbling booting anything non-Android.
- **The one-command fix:** once Armada is running:
  1. In the Steam UI, press **STEAM → Power → Switch to Desktop**.
  2. Open the **Konsole** app (the terminal).
  3. Type `sudo armada-flash-loader` and press Enter (password: `armada`).

  This installs [Retroid's own fixed bootloader build](https://github.com/RetroidPocket/u-boot/releases/tag/rp-v1.0.1)
  — the official corrected version of the exact component the bad OTA broke. It
  **backs up your current bootloader first** and **verifies the write** before
  finishing, and it touches nothing else on the device. From the **next boot
  onward**, every screen renders cleanly.

> ⚠️ This is the one step in the basic setup that writes to the device, which is
> why it's optional and manual. If the command reports any error, **stop, don't
> reboot, and ask for help** (see [Reporting a bug](#reporting-a-bug)) —
> recovery is possible, but let someone look first.

---

## 5. Sign in to Steam

On first boot Armada lands on the familiar Steam login:

1. Connect to **Wi-Fi** when prompted.
2. Sign in with your Steam account (you can use the Steam mobile app's QR-code
   sign-in — usually the fastest way on a handheld).
3. That's it. You get the full SteamOS-style gamepad interface: your library,
   the store, friends, cloud saves. Install a game and play.

Windows/x86 games run through the built-in compatibility layer (Proton + FEX) —
there's nothing to configure; just install and launch.

### Mini V2 only: the UI scale settles itself

The Mini V2's near-square screen confuses Steam's automatic scaling, so on the
very first boot the interface can look oversized and cut off. Armada fixes this
for you automatically: within a couple of minutes of reaching the Steam home
screen, the UI snaps to a sane size — one time, and it sticks from then on.

If it hasn't settled after a few minutes (or you'd like a different size):
**Settings → Display** → turn **off** *Automatically Scale Interface* → adjust
the slider to taste. Your manual choice always wins — Armada never overrides it. (Also expected on the Mini's square panel:
widescreen games show black bars top and bottom — against the black bezel they
mostly disappear.)

---

## 6. Getting updates

You never need to re-flash the SD card. Armada updates itself, exactly like a
Steam Deck:

1. **Steam Settings → System → Check for updates.**
2. If there's a new version, apply it and restart when prompted.

Updates are cryptographically signed and your device verifies them before
installing. Internal-storage installs (next section) update the same way.

---

## 7. Optional: install to internal storage (RP5)

> ⚠️ **This step is destructive to Android — read before touching it.**
> Everything above runs from the SD card and changes nothing on your device.
> This optional step is different: it repartitions the internal storage and
> **factory-resets Android** (Android itself stays installed, but all your
> Android apps and their data are erased). Currently validated on the
> **Retroid Pocket 5** only.

**Why do it:** games load dramatically faster from internal storage (roughly
60% faster in testing — internal storage is far quicker than any SD card at the
kind of reads games do), and you no longer need the SD card in the device.

**What it does NOT do:** it does not flash the bootloader. The stock firmware
already knows how to boot the internal install, so the worst case is always
"put the SD card back in and boot from it" — there is no way to brick the
device with this.

**How:**

1. Boot Armada **from the SD card** as usual.
2. **STEAM → Power → Switch to Desktop.**
3. Open the **Armada Installer** app on the desktop.
4. The big slider chooses **how to split the internal storage between Android
   and Armada** — e.g. leave Android 20–32 GB and give Armada the rest. Slide
   it to taste.
5. Click install and confirm. It backs up the partition table first, then takes
   a few minutes. Keep the device plugged in.
6. When it's done: **power off, remove the SD card, power on holding Vol+** —
   Armada now boots from internal storage. Power on *without* Vol+ for
   (freshly reset) Android.

If Armada is already installed internally, the same app instead offers
**Reinstall** and **Remove & Restore Android**.

> ⚠️ **Reinstall wipes your installed games** (it rebuilds the Armada partition
> from scratch). Your Steam cloud saves survive, but you'll re-download the
> games themselves.

---

## 8. Going back

**Just want Android for a bit?** Power on without holding Vol+ (or pop the SD
card out). If you never did the internal install, Android is 100% untouched.

**Done with Armada entirely (SD-only setup)?** Take the SD card out. That's the
whole uninstall. Reformat the card if you want it back for something else.

**Undo an internal install?** Boot Armada from the SD card, open the **Armada
Installer** in Desktop Mode, and choose **Remove & Restore Android**. It removes
Armada from internal storage and gives all the space back to Android, which
re-initialises it full-size on the next boot. (Remember: Android was already
factory-reset when you installed — the removal can't bring old Android data
back.)

---

## 9. Troubleshooting FAQ

**Black screen after picking a boot entry.**
You most likely picked the wrong entry in the boot menu, or the card wasn't
seated. Hold Power ~10 seconds to force off, then redo the ritual: hold Vol+,
power on, choose **Boot**. If the advanced GRUB menu ever appears, just let the
top entry boot on its own.

**First boot seems stuck.**
Give it up to 5 minutes — the first boot expands the filesystem and sets up
Steam. If it's clearly frozen after that, force off (hold Power ~10 s) and boot
again; if it never comes up, re-flash the card (flashes do occasionally fail
silently — Etcher's verify step catches this).

**A game launches with no sound.**
Known quirk: tap the **Home** button once (open and close the Steam menu) and
audio kicks in. Also, if audio ever drops out mid-game, Armada's audio watchdog
heals it automatically within about 30 seconds — just wait.

**No audio at all on first boot.**
Give it a minute (the audio system self-checks and self-heals on a ~30-second
cycle), and try the Home-button tap above. Still silent after a reboot? That's
a bug — please report it.

**The boot menu never appears / SD not detected.**
Make sure you're holding **Volume Up** *before* pressing Power and keep holding
it. If the menu appears but there's no SD option: power off, reseat the card
firmly, try again. If it's still missing, test the card in your PC — and note
that some cheap/counterfeit cards flash fine but fail in-device; a name-brand A2
card is the fix.

**Steam UI is huge / cut off (Mini V2).**
Give it a couple of minutes on the home screen — it fixes itself on first boot.
Still wrong? See [the UI scale section](#mini-v2-only-the-ui-scale-settles-itself).

**Garbled text before Linux starts (Mini V2).**
Cosmetic, caused by a faulty Retroid Android update, one-command fix — see
[the Mini V2 section](#mini-v2-owners-why-do-the-boot-screens-look-garbled).

**A game hard-locks the screen.**
The GPU driver usually recovers you back to Steam in a few seconds. If it
doesn't and you have to reboot, please report which game it was — that's
exactly the data being collected right now.

### Reporting a bug

Open a **GitHub issue** on this repository with three things: **your device**,
**the Armada version** (Steam Settings → System shows it), and **what happened**
(what you did, what you expected, what you got). Screenshots or a phone video
help a lot. For logs, there's a one-command collector: in Desktop Mode open
Konsole and run `sudo armada-report` — it bundles everything useful into a
`armada-report-<date>.tar.gz` on the Desktop (no passwords or Wi-Fi secrets
included), which you can drag straight into the GitHub issue.

---

## 10. If things go really wrong (recovery basics)

Keep these two facts in your back pocket:

1. **The SD card always boots.** Nothing Armada does — updates, the internal
   install, anything — ever modifies the SD card's ability to boot, and booting
   without it always gets stock Android (unless you chose the internal
   install, in which case Vol+ picks Armada and no-Vol+ picks Android). "Put
   the SD card back in" fixes almost every situation.
2. **The stock low-level recovery tools still exist.** Retroid devices keep
   their standard fastboot/recovery mechanisms underneath everything, exactly
   as shipped — Armada doesn't remove or replace them. You should never need
   them, but if you ever end up in a truly weird state, open an issue *before*
   experimenting and someone will walk you through it.

Have fun out there. 🎮
