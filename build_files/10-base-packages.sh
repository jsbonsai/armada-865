#!/bin/bash
set -euxo pipefail

dnf5 -y install --nogpgcheck \
    --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' \
    terra-release

dnf5 -y install --setopt=install_weak_deps=False \
    sddm \
    pipewire \
    pipewire-alsa \
    pipewire-pulseaudio \
    pulseaudio-utils \
    wireplumber \
    alsa-lib \
    alsa-ucm \
    alsa-utils \
    qcom-firmware \
    atheros-firmware \
    NetworkManager \
    NetworkManager-wifi \
    iwd \
    wpa_supplicant \
    bluez \
    dbus-broker \
    python3-gobject \
    python3-websocket-client \
    polkit \
    sudo \
    rsync \
    curl \
    jq \
    lsof \
    unzip \
    evtest \
    dbus-x11 \
    xdg-user-dirs \
    xdg-terminal-exec \
    btrfs-progs \
    parted \
    gdisk \
    binutils \
    xz \
    bzip2-libs \
    dracut \
    dracut-config-generic \
    plymouth \
    plymouth-system-theme \
    plymouth-theme-spinner \
    qt6-qttools \
    qt6-qtvirtualkeyboard \
    zenity \
    seatd

dnf5 -y install --setopt=install_weak_deps=False \
    google-noto-sans-cjk-vf-fonts \
    google-noto-sans-thai-vf-fonts \
    google-noto-sans-arabic-vf-fonts \
    google-noto-sans-hebrew-vf-fonts \
    google-noto-sans-devanagari-vf-fonts \
    google-noto-color-emoji-fonts

dnf5 -y install --setopt=install_weak_deps=False \
    plasma-workspace \
    plasma-desktop \
    plasma-pa \
    maliit-keyboard \
    libappindicator-gtk3 \
    libdbusmenu-gtk3 \
    kdialog \
    kio-extras \
    kscreen \
    konsole \
    dolphin

dnf5 -y install --setopt=install_weak_deps=False \
    --repofrompath 'copr-ublue-os-packages,https://download.copr.fedorainfracloud.org/results/ublue-os/packages/fedora-$releasever-$basearch/' \
    --setopt=copr-ublue-os-packages.gpgcheck=0 \
    --setopt=copr-ublue-os-packages.repo_gpgcheck=0 \
    flatpak \
    bazaar \
    krunner-bazaar

mkdir -p /etc/flatpak/remotes.d
curl --retry 3 -fsSL -o /etc/flatpak/remotes.d/flathub.flatpakrepo \
    https://dl.flathub.org/repo/flathub.flatpakrepo
