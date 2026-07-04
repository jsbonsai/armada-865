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

case "$mode" in
    input) setup_input ;;
    audio) setup_audio ;;
    all)
        setup_input
        setup_audio
        ;;
    *)
        echo "Usage: $0 [input|audio|all]" >&2
        exit 1
        ;;
esac
