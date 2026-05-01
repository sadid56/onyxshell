#!/bin/bash

set -e

# Colors
GREEN="\033[1;32m"
BLUE="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

# Auto-yes flag
AUTO_YES=false
if [[ "$1" == "--yes" ]]; then
    AUTO_YES=true
fi

# Confirmation function
confirm() {
    if $AUTO_YES; then
        return 0
    fi

    while true; do
        read -rp "$(echo -e "${BLUE}[?] $1 (y/n): ${RESET}")" choice
        case "$choice" in
            [Yy]*) return 0 ;;
            [Nn]*) echo -e "${RED}[-] Skipped.${RESET}"; return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}    Welcome to the Onyxshell Installer!             ${RESET}"
echo -e "${BLUE}====================================================${RESET}"

# 1. System Update
if confirm "Update system packages?"; then
    echo -e "\n${BLUE}[*] Updating system packages...${RESET}"
    sudo pacman -Syu --noconfirm
fi

# 2. Check and install yay (AUR Helper)
if ! command -v yay &> /dev/null; then
    if confirm "Install yay AUR helper?"; then
        echo -e "${BLUE}[*] Installing yay AUR helper...${RESET}"
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        cd /tmp/yay-bin
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay-bin
    fi
else
    echo -e "${GREEN}[+] yay is already installed.${RESET}"
fi

# 3. Define Required Packages
OFFICIAL_PACKAGES=(
    hyprland
    hyprlock
    hyprshot
    kitty
    yazi
    rofi
    waybar
    swaync
    wl-clipboard
    cliphist
    playerctl
    brightnessctl
    wireplumber
    network-manager-applet
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
    awww
    cava
    gnome-keyring
    libnotify
    pavucontrol
    xdg-desktop-portal 
    xdg-desktop-portal-hyprland 
    xdg-desktop-portal-gtk
    7zip
    gnome-themes-extra
    adwaita-icon-theme
    nwg-look
)

AUR_PACKAGES=(
    brave-bin
    wlogout
    pyprland
)

# 4. Install Packages
if confirm "Install official packages?"; then
    echo -e "\n${BLUE}[*] Installing official packages...${RESET}"
    sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
fi

if confirm "Install AUR packages?"; then
    echo -e "\n${BLUE}[*] Installing AUR packages...${RESET}"
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
fi

# 5. Backup Existing Configs
if confirm "Backup existing configurations?"; then
    echo -e "\n${BLUE}[*] Backing up existing configurations...${RESET}"
    CONFIG_DIR="$HOME/.config"
    BACKUP_DIR="$HOME/.config/onyxshell_backup_$(date +%Y%m%d_%H%M%S)"

    mkdir -p "$BACKUP_DIR"

    for folder in hypr rofi swaync waybar wlogout cava theme; do
        if [ -d "$CONFIG_DIR/$folder" ]; then
            mv "$CONFIG_DIR/$folder" "$BACKUP_DIR/$folder"
            echo -e "${GREEN}[+] Backed up $folder to $BACKUP_DIR${RESET}"
        fi
    done
fi

# 6. Copy Onyxshell Configs
if confirm "Install Onyxshell configurations? (this will overwrite configs)"; then
    echo -e "\n${BLUE}[*] Installing Onyxshell configurations...${RESET}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp -r "$SCRIPT_DIR/.config/"* "$HOME/.config/"
fi

# 7. Make Scripts Executable
if confirm "Set executable permissions for scripts?"; then
    echo -e "\n${BLUE}[*] Setting execution permissions for scripts...${RESET}"
    chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
fi

echo -e "\n${BLUE}====================================================${RESET}"
echo -e "${GREEN}    Installation Complete!                          ${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo -e "You can now log out and select ${GREEN}Hyprland${RESET} from your Display Manager (like SDDM or GDM)."
echo -e "Enjoy your new Onyxshell setup!"
