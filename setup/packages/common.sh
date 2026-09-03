#!/usr/bin/env bash

# ==============================================================================
# Central Package Repository for Onyxshell (Arch, Fedora, openSUSE)
# ==============================================================================

SHARED_BASE_PKGS=(
    hyprland
    hypridle
    hyprlock
    hyprpicker
    hyprpaper
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    jq
    socat
    kitty
    fish
    starship
    fastfetch
    cava
    htop
    wl-clipboard
    brightnessctl
    wireplumber
    pipewire
    gnome-keyring
    libsecret
    grim
    slurp
    papirus-icon-theme
    gnome-themes-extra
    qt5ct
    qt6ct
    gcc
    make
    polkit-gnome
)

# 2. Package mappings per distribution
get_distro_packages() {
    local target_distro="${1:-arch}"
    local pkgs=("${SHARED_BASE_PKGS[@]}")

    case "$target_distro" in
        arch)
            pkgs+=(
                hyprshot
                hyprsunset
                quickshell
                matugen
                python
                cliphist
                yazi
                satty
                pipewire-pulse
                noto-fonts
                noto-fonts-cjk
                noto-fonts-emoji
                ttf-jetbrains-mono-nerd
            )
            ;;
        fedora)
            pkgs+=(
                cliphist
                python3
                pipewire-pulseaudio
                google-noto-sans-cjk-fonts
                google-noto-color-emoji-fonts
                jetbrains-mono-fonts-all
            )
            ;;
        opensuse)
            pkgs+=(
                python3
                pipewire-pulseaudio
                noto-sans-fonts
                noto-coloremoji-fonts
                jetbrains-mono-fonts
            )
            ;;
    esac

    echo "${pkgs[@]}"
}
