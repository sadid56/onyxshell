#!/bin/bash

set -e

GREEN="\033[1;32m"
BLUE="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BOLD="\033[1m"
RESET="\033[0m"

AUTO_YES=false
if [[ "$1" == "--yes" || "$1" == "-y" ]]; then
    AUTO_YES=true
fi

confirm() {
    if $AUTO_YES; then
        return 0
    fi
    while true; do
        read -rp "$(echo -e "${BLUE}[?] $1 [Y/n]: ${RESET}")" choice
        choice="${choice:-y}"
        case "$choice" in
            [Yy]*) return 0 ;;
            [Nn]*)
                echo -e "${YELLOW}[-] Skipped.${RESET}"
                return 1
                ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

if [ ! -f /etc/arch-release ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" != "arch" && "$ID_LIKE" != *"arch"* ]]; then
            echo -e "${RED}[!] Error: Onyxshell installer is dedicated exclusively for Arch Linux and Arch-based distributions.${RESET}"
            echo -e "${YELLOW}[i] Detected: ${PRETTY_NAME:-$ID}${RESET}"
            exit 1
        fi
    else
        echo -e "${RED}[!] Error: Could not verify Arch Linux distribution.${RESET}"
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}${BOLD}       ❄️  Onyxshell Desktop Setup (Arch Linux)  ❄️${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo ""

if confirm "Update system packages with pacman?"; then
    sudo pacman -Syu --noconfirm
fi

BASE_PKGS=(
    base-devel git libinput-tools curl wget rsync jq socat
    hyprland hypridle hyprlock hyprpolkitagent
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    quickshell
    python python-psutil
    kitty fish starship fastfetch cava yazi htop
    wl-clipboard cliphist playerctl brightnessctl
    wireplumber pipewire pipewire-pulse
    gnome-keyring libsecret
    grim slurp satty
    ttf-inter noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
    papirus-icon-theme qt5ct qt6ct
)

echo -e "${BLUE}[+] Installing official repository packages...${RESET}"
sudo pacman -S --needed --noconfirm "${BASE_PKGS[@]}"

BACKUP_DIR="$HOME/.config/onyxshell_backup_$(date +%Y%m%d_%H%M%S)"
CONFIG_ITEMS=(
    hypr quickshell kitty fastfetch cava nvim
    xdg-desktop-portal fish matugen htop
    fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct
    starship.toml kdeglobals
)

if confirm "Backup existing configurations to $BACKUP_DIR and install Onyxshell configs?"; then
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$HOME/.config"

    for item in "${CONFIG_ITEMS[@]}"; do
        if [ -e "$HOME/.config/$item" ]; then
            mv "$HOME/.config/$item" "$BACKUP_DIR/"
            echo -e "  ${YELLOW}[*] Backed up $item${RESET}"
        fi
    done

    echo -e "${BLUE}[+] Copying Onyxshell dotfiles to ~/.config/...${RESET}"
    cp -r "$SCRIPT_DIR/.config/"* "$HOME/.config/"

    chmod +x "$HOME/.config/hypr/scripts/"* 2>/dev/null || true
    chmod +x "$HOME/.config/quickshell/scripts/"* 2>/dev/null || true

    echo -e "${GREEN}[✔️] Configs successfully installed!${RESET}"
fi

if [ -f "$HOME/.config/fontconfig/fonts.conf" ]; then
    fc-cache -fv &>/dev/null || true
fi

if confirm "Set Fish as your default user shell?"; then
    FISH_PATH="$(which fish)"
    if [ -n "$FISH_PATH" ] && [ "$SHELL" != "$FISH_PATH" ]; then
        if ! grep -q "$FISH_PATH" /etc/shells; then
            echo "$FISH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$FISH_PATH" "$USER"
        echo -e "${GREEN}[✔️] Default shell changed to Fish.${RESET}"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}====================================================${RESET}"
echo -e "${GREEN}${BOLD}   🎉  Onyxshell Installation Complete! 🎉${RESET}"
echo -e "${GREEN}${BOLD}====================================================${RESET}"
echo -e "${BLUE}Launch Hyprland to enjoy your new Onyxshell desktop!${RESET}"
echo ""
