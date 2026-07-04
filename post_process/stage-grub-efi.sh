#!/bin/bash
# Stage GRUB/EFI boot payload for SM8250 (D1: GRUB path, not ABL /KERNEL bootimg).
set -euxo pipefail

RAW="${1:-output/image/disk.raw}"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
ARMADA_LIB="${REPO_ROOT}/system_files/usr/lib/armada"
DTB_LIST="${ARMADA_LIB}/supported-dtbs"
SM8250_DTBS=(sm8250-retroidpocket-rp5 sm8250-retroidpocket-flip2)

[[ -f "${RAW}" ]] || { echo "raw image not found: ${RAW}"; exit 1; }
[[ -r "${DTB_LIST}" ]] || { echo "missing ${DTB_LIST}"; exit 1; }
command -v grub-mkstandalone >/dev/null \
    || { echo "ERROR: grub-mkstandalone not found (apt: grub-efi-arm64-bin)"; exit 1; }

WORK=$(mktemp -d)
LOOP=$(sudo losetup -fP --show "${RAW}")
trap 'sudo umount "${WORK}/p1" 2>/dev/null||true; sudo umount "${WORK}/p2" 2>/dev/null||true; sudo losetup -d "${LOOP}" 2>/dev/null||true; rm -rf "${WORK}"' EXIT

mkdir -p "${WORK}/p1" "${WORK}/p2"
sudo mount "${LOOP}p2" "${WORK}/p2"

DEPLOY=$(sudo ls "${WORK}/p2/ostree" | grep '^default-' | head -1)
BOOTDIR="${WORK}/p2/ostree/${DEPLOY}"
KVER=$(basename "$(sudo ls "${BOOTDIR}"/vmlinuz-* | head -1)" | sed 's/^vmlinuz-//')
BLS=$(sudo ls "${WORK}/p2"/loader*/entries/*.conf | head -1)
OPTIONS_LINE=$(sudo sed -n 's/^options //p' "${BLS}" | head -1)

# Drop serial console; keep ostree + splash kargs.
CMDLINE=""
_ostree=""
for _t in ${OPTIONS_LINE}; do
    case "${_t}" in
        console=ttyS0) continue ;;
        ostree=*) _ostree="${_t}" ;;
        *) CMDLINE="${CMDLINE} ${_t}" ;;
    esac
done
CMDLINE="${_ostree}${CMDLINE} quiet rootwait console=tty0 video=efifb:off"

sudo cat "${BOOTDIR}/vmlinuz-${KVER}" > "${WORK}/vmlinuz"
sudo cat "${BOOTDIR}/initramfs-${KVER}.img" > "${WORK}/initramfs.img"

cat > "${WORK}/grub.cfg" <<EOF
set timeout=5
set default=0
set timeout_style=menu

menuentry 'Retroid Pocket 5' {
    search --set -f /KERNEL
    linux /KERNEL ${CMDLINE}
    initrd /INITRD
    devicetree /boot/grub/sm8250-retroidpocket-rp5.dtb
}

menuentry 'Retroid Pocket Flip 2' {
    search --set -f /KERNEL
    linux /KERNEL ${CMDLINE}
    initrd /INITRD
    devicetree /boot/grub/sm8250-retroidpocket-flip2.dtb
}
EOF

# Embed the menu in bootaa64.efi — Ubuntu's monolithic .efi looks for grub.cfg at a
# hardcoded prefix and drops to the rescue shell on RP5 when it is not found.
grub-mkstandalone -O arm64-efi -o "${WORK}/bootaa64.efi" -p /boot/grub \
    --modules "part_msdos part_gpt fat search search_fs_file linux initrd normal fdt" \
    "boot/grub/grub.cfg=${WORK}/grub.cfg"

sudo mount "${LOOP}p1" "${WORK}/p1"
sudo mkdir -p "${WORK}/p1/EFI/BOOT" "${WORK}/p1/boot/grub"
sudo cp "${WORK}/vmlinuz" "${WORK}/p1/KERNEL"
sudo cp "${WORK}/initramfs.img" "${WORK}/p1/INITRD"
sudo cp "${WORK}/bootaa64.efi" "${WORK}/p1/EFI/BOOT/bootaa64.efi"
sudo cp "${WORK}/grub.cfg" "${WORK}/p1/boot/grub/grub.cfg"
sudo cp "${WORK}/grub.cfg" "${WORK}/p1/EFI/BOOT/grub.cfg"

for _name in "${SM8250_DTBS[@]}"; do
    _dtb="${BOOTDIR}/dtb/qcom/${_name}.dtb"
    sudo test -f "${_dtb}" || { echo "ERROR: missing DTB ${_dtb}"; exit 1; }
    sudo cp "${_dtb}" "${WORK}/p1/boot/grub/${_name}.dtb"
done

if command -v grub-editenv >/dev/null; then
    grub-editenv "${WORK}/grubenv" create
    sudo cp "${WORK}/grubenv" "${WORK}/p1/boot/grub/grubenv"
fi

sudo sync
echo "Staged GRUB/EFI payload on ${RAW} (kver=${KVER})"
