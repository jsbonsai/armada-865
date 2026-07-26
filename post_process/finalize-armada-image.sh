#!/bin/bash
# Post-BIB: stage ROCKNIX ABL files and compress.

set -euxo pipefail

RAW_IMAGE="${1:-output/raw/disk.raw}"
ROCKNIX_ABL_VERSION="${ROCKNIX_ABL_VERSION:-v1.1.5}"
OUT="${OUT:-output/armada-$(TZ='America/New_York' date +%Y%m%d).img.gz}"
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ! -f "${RAW_IMAGE}" ]]; then
    echo "ERROR: raw image not found at ${RAW_IMAGE}"
    echo "Run 'just build-raw' first."
    exit 1
fi

WORK=$(mktemp -d)
trap "sudo umount '${WORK}/mnt' 2>/dev/null || true; sudo losetup -d \"\$(cat ${WORK}/loop 2>/dev/null)\" 2>/dev/null || true; rm -rf '${WORK}'" EXIT

curl -fsSL -o "${WORK}/abl.tar.gz" \
    "https://github.com/ROCKNIX/abl/releases/download/${ROCKNIX_ABL_VERSION}/rocknix-abl-${ROCKNIX_ABL_VERSION}.tar.gz"
mkdir -p "${WORK}/abl-extracted"
tar -xzf "${WORK}/abl.tar.gz" -C "${WORK}/abl-extracted"

LOOP=$(sudo losetup -fP --show "${RAW_IMAGE}")
echo "${LOOP}" > "${WORK}/loop"
sleep 1

ESP="${LOOP}p1"
if ! sudo blkid "${ESP}" | grep -q 'TYPE="vfat"'; then
    echo "ERROR: ${ESP} is not vfat. BIB partition layout may have changed."
    sudo blkid "${LOOP}"*
    exit 1
fi

mkdir -p "${WORK}/mnt"
sudo mount "${ESP}" "${WORK}/mnt"

sudo mkdir -p "${WORK}/mnt/rocknix_abl"
# One image serves all devices, so stage a self-contained folder per SoC.
# vfat has no Unix ownership, so `cp -a` would error on chown under set -e.
ABL_SRC=$(ls -d "${WORK}/abl-extracted"/rocknix-abl-*)
sudo cp "${REPO_ROOT}/abl/README" "${WORK}/mnt/rocknix_abl/README"
for soc in SM8250 SM8550 SM8650 SM8750; do
    d="${WORK}/mnt/rocknix_abl/${soc}"
    sudo mkdir -p "$d"
    sudo cp "${ABL_SRC}/abl_signed-${soc}.elf" "${ABL_SRC}/abl_signed-${soc}.elf.sha256" "$d/"
    for s in flash_abl backup_abl restore_backup_abl; do
        sed "s/%DEVICE%/${soc}/g" "${REPO_ROOT}/abl/${s}.sh.template" \
            | sudo tee "$d/${s}.sh" >/dev/null
    done
    sudo chmod 0755 "$d"/*.sh
done

# Retroid rp-v1.0.1 U-Boot loader images. Retroid's Android OTA shipped a bad
# loader for the Mini V2 (simple-framebuffer geometry mismatch) that garbles the
# U-Boot menu AND GRUB; these are the fixed per-device builds. Staged on the SD
# so `sudo armada-flash-loader` works offline from the booted system.
RETROID_UBOOT_URL="https://github.com/RetroidPocket/u-boot/releases/download/rp-v1.0.1"
declare -A RETROID_UBOOT_SHA=(
    [rp5]=af2c337f7f9576833581c99a797a05c5a9f3d5afb5f5ef8f8e8404e27ff0b088
    [flip2]=5055dd574733da49606a27d5a1a4831326ea078a13ed9e5b677146ecc1a3871d
    [rpmini]=ee837fa8b9c9e2093414cd87d08f79e3fea60340009409403eee6e4404cda229
    [rpminiv2]=7f110ac7c8e6a98b7507418f3ffd7865ac6395dfc94589492c1d99e114b6b8f8
)
sudo mkdir -p "${WORK}/mnt/retroid_loader"
for dev in rp5 flip2 rpmini rpminiv2; do
    f="u-boot-sm8250-retroidpocket-${dev}.img"
    curl -fsSL -o "${WORK}/${f}" "${RETROID_UBOOT_URL}/${f}"
    echo "${RETROID_UBOOT_SHA[$dev]}  ${WORK}/${f}" | sha256sum -c - >/dev/null
    sudo cp "${WORK}/${f}" "${WORK}/mnt/retroid_loader/${f}"
done
printf '%s\n' \
    "Fixed Retroid U-Boot loader images (rp-v1.0.1, github.com/RetroidPocket/u-boot)." \
    "If your boot menu / GRUB renders garbled (Mini V2 after a Retroid Android OTA)," \
    "boot Armada and run:  sudo armada-flash-loader" \
    "Or from a PC in fastboot mode (Vol- + Power):" \
    "  fastboot flash loader u-boot-sm8250-retroidpocket-<your-device>.img" \
    | sudo tee "${WORK}/mnt/retroid_loader/README" >/dev/null

# SM8250 boots via GRUB/EFI (see D1); other SoCs fall through to /KERNEL when EFI is absent.
if [ "${ARMADA_GRUB_BOOT:-0}" != "1" ]; then
    if [ -d "${WORK}/mnt/EFI" ]; then sudo mv "${WORK}/mnt/EFI" "${WORK}/mnt/EFI.disabled"; fi
fi
sudo sync
sudo umount "${WORK}/mnt"

# ostree must NOT manage the bootloader: at OTA finalize grub2-mkconfig dies on
# the composefs root and the staged deployment is dropped (device boots the old
# build). armada-grub-efi-update owns the ESP grub.cfg; bootloader=none still
# writes the BLS entries it consumes. Edit the repo config directly (GKeyFile
# ini) so the CI host doesn't need the ostree CLI.
ROOTP="${LOOP}p3"
mkdir -p "${WORK}/rootmnt"
sudo mount "${ROOTP}" "${WORK}/rootmnt"
OSTREE_CFG=$(sudo find "${WORK}/rootmnt" -maxdepth 4 -path '*/ostree/repo/config' | head -1)
[ -n "${OSTREE_CFG}" ] || { echo "ERROR: ostree repo config not found on ${ROOTP}"; exit 1; }
sudo python3 - "${OSTREE_CFG}" <<'PYEOF'
import configparser, sys
p = sys.argv[1]
c = configparser.ConfigParser()
c.read(p)
if not c.has_section('sysroot'):
    c.add_section('sysroot')
c.set('sysroot', 'bootloader', 'none')
with open(p, 'w') as f:
    c.write(f, space_around_delimiters=False)
PYEOF
sudo grep -A3 '^\[sysroot\]' "${OSTREE_CFG}"
sudo umount "${WORK}/rootmnt"

# Android shows this label when copying the ABL
sudo fatlabel "${ESP}" ARMADA

# MBR, not GPT: a fixed-size GPT image flashed to a larger card strands the backup
# GPT mid-disk and Android's vold rejects the card. MBR has no end-of-disk
# structure, so it reads on any card. SD image only; internal installs stay GPT.
TABLE=$(sudo sfdisk -J "${LOOP}")
mapfile -t PARTS < <(jq -r '.partitiontable.partitions[] | "\(.start) \(.size)"' <<<"${TABLE}")
[ "${#PARTS[@]}" -eq 3 ] || { echo "ERROR: expected 3 partitions, got ${#PARTS[@]}"; sudo sfdisk -l "${LOOP}"; exit 1; }
read -r P1_START P1_SIZE <<<"${PARTS[0]}"
read -r P2_START P2_SIZE <<<"${PARTS[1]}"
read -r P3_START P3_SIZE <<<"${PARTS[2]}"
SECTORS=$(sudo blockdev --getsz "${LOOP}")

# Zero the two GPT copies (primary LBA 1-33, backup last 33 LBAs); dd avoids a
# gdisk dependency. The guards refuse any layout where a zero could hit a partition.
[ "$(jq -r '.partitiontable.sectorsize // 512' <<<"${TABLE}")" = 512 ] \
    || { echo "ERROR: non-512-byte sectors; GPT-zero math assumes 512"; exit 1; }
[ "${P1_START}" -ge 34 ] || { echo "ERROR: p1 starts inside the primary-GPT span"; exit 1; }
[ "$((P3_START + P3_SIZE))" -le "$((SECTORS - 33))" ] || { echo "ERROR: p3 overlaps the backup-GPT span"; exit 1; }
sudo dd if=/dev/zero of="${LOOP}" bs=512 seek=1 count=33 conv=notrunc status=none
sudo dd if=/dev/zero of="${LOOP}" bs=512 seek=$((SECTORS - 33)) count=33 conv=notrunc status=none

sudo sfdisk --label dos "${LOOP}" <<EOF
${P1_START},${P1_SIZE},c,*
${P2_START},${P2_SIZE},da
${P3_START},${P3_SIZE},da
EOF

sudo sfdisk -J "${LOOP}" \
    | jq -e '.partitiontable.label=="dos" and (.partitiontable.partitions|length)==3' >/dev/null \
    || { echo "ERROR: MBR conversion verify failed"; sudo sfdisk -l "${LOOP}"; exit 1; }

sudo losetup -d "${LOOP}"
rm "${WORK}/loop"

GZIP_LEVEL="${GZIP_LEVEL:-6}"
mkdir -p "$(dirname "${OUT}")"
# -n: don't store the source filename in the gzip header — otherwise 7-Zip /
# Archive Utility extract the image as "disk.raw" instead of the .gz's own name.
pigz -f -n "-${GZIP_LEVEL}" -p "$(nproc)" -c "${RAW_IMAGE}" > "${OUT}"
rm -f "${RAW_IMAGE}"

echo "Built: ${OUT}"
echo "Flash to SD with:  zcat ${OUT} | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress"
