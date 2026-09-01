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
    playerctl
    brightnessctl
    wireplumber
    pipewire
    gnome-keyring
    libsecret
    grim
    slurp
    papirus-icon-theme
    qt5ct
    qt6ct
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
                hyprpolkitagent
                quickshell
                matugen
                python
                python-psutil
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
                python3-psutil
                pipewire-pulseaudio
                google-noto-sans-cjk-fonts
                google-noto-color-emoji-fonts
                jetbrains-mono-fonts-all
            )
            ;;
        opensuse)
            pkgs+=(
                python3
                python3-psutil
                pipewire-pulseaudio
                noto-sans-fonts
                noto-coloremoji-fonts
                jetbrains-mono-fonts
            )
            ;;
    esac

    echo "${pkgs[@]}"
}
