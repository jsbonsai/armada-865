#!/usr/bin/env bash
# Persistent early boot bring-up (survives rpm-ostree overlay wipe).
# Usage: sm8250-bringup-early.sh [input|audio|all]
set -euo pipefail

mode="${1:-all}"

mount_bind() {
    local src=$1 dst=$2
    [[ -d "$src" ]] || return 0
    mkdir -p "$dst"
    if mountpoint -q "$dst" 2>/dev/null; then
        return 0
    fi
    mount --bind "$src" "$dst"
}

setup_boot() {
    mkdir -p /etc/systemd/system/armada-bootimg-sync.service.d
    if [[ -f /etc/armada/sm8250-grub-efi.conf ]]; then
        cp -f /etc/armada/sm8250-grub-efi.conf \
            /etc/systemd/system/armada-bootimg-sync.service.d/sm8250-grub-efi.conf
    fi
    touch /etc/armada/.sm8250-grub-efi
    if [[ -x /etc/armada/armada-grub-efi-update ]]; then
        chmod +x /etc/armada/armada-grub-efi-update /etc/armada/armada-bootimg-update 2>/dev/null || true
    fi
    if [[ -x /etc/armada/launch-steam ]]; then
        mount_bind /etc/armada/launch-steam /usr/libexec/armada/launch-steam
    fi
}

setup_input() {
    mount_bind /etc/armada/inputplumber/devices /usr/share/inputplumber/devices
    mount_bind /etc/armada/inputplumber/capability_maps /usr/share/inputplumber/capability_maps
    if [[ -x /etc/armada/controller-type ]]; then
        mount_bind /etc/armada/controller-type /usr/libexec/armada/controller-type
    fi
    if [[ -x /etc/armada/launch-steam ]]; then
        mount_bind /etc/armada/launch-steam /usr/libexec/armada/launch-steam
    fi
}

wait_retroid_card() {
    local i
    for i in $(seq 1 60); do
        if grep -q RetroidPocket /proc/asound/cards 2>/dev/null; then
            return 0
        fi
        sleep 0.5
    done
    return 1
}

setup_audio() {
    wait_retroid_card || return 0
    mount_bind /etc/armada/alsa/ucm2/conf.d/sm8250 /usr/share/alsa/ucm2/conf.d/sm8250
    mount_bind /etc/armada/alsa/ucm2/Qualcomm/sm8250 /usr/share/alsa/ucm2/Qualcomm/sm8250
    if [[ -d /etc/armada/alsa/ucm2/codecs/wsa881x ]]; then
        mount_bind /etc/armada/alsa/ucm2/codecs/wsa881x /usr/share/alsa/ucm2/codecs/wsa881x
    fi
    /etc/armada/sm8250-audio-init mixers
}

setup_power() {
    # Per-device fan/power overrides: install the model's fragment as the /etc
    # powerd override (merged over the factory config by armada-powerd). The
    # version stamp on line 1 gates reinstall so a shipped update can revise the
    # curves on provisioned devices, while an unchanged stamp leaves any local
    # hand-tuning alone between updates. Mini V2 only today; other models keep
    # factory behavior (no fragment -> no override).
    local frag dst=/etc/armada/power-profiles.conf
    case "$(tr -d '\0' < /proc/device-tree/model 2>/dev/null)" in
        *"Mini V2"*) frag=/usr/share/armada/power-profiles.d/retroid-pocket-mini-v2.conf ;;
        *"Pocket 5"*) frag=/usr/share/armada/power-profiles.d/retroid-pocket-5.conf ;;
        # Flip 2 keeps factory curves until its own ear-test/calibration pass.
        *) return 0 ;;
    esac
    [ -r "$frag" ] || return 0
    if [ -f "$dst" ] && [ "$(head -1 "$frag")" = "$(head -1 "$dst")" ]; then
        return 0
    fi
    # || return 0: bringup runs under set -e; a failed install must not abort
    # the rest of bring-up (SoundWire PM pinning below is audio-critical).
    install -m 0644 "$frag" "$dst" 2>/dev/null || return 0
    systemctl try-restart armada-powerd 2>/dev/null || true
}

case "$mode" in
    boot) setup_boot; setup_power ;;
    input) setup_input ;;
    audio) setup_audio ;;
    all)
        setup_boot
        setup_input
        setup_audio
        setup_power
        ;;
    *)
        echo "Usage: $0 [input|audio|all]" >&2
        exit 1
        ;;
esac

# Belt-and-suspenders for 99-armada-sm8250-wsa-pm.rules: pin SoundWire devices
# (WSA881x speaker amps + masters) out of runtime suspend; wake races leave the
# amps dead-silent with no DSP errors.
for _sdw in /sys/bus/soundwire/devices/*/power/control; do
    echo on > "$_sdw" 2>/dev/null || true
done
