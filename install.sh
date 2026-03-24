#!/bin/bash

set -e

# Colors
GREEN="\033[1;32m"
BLUE="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}    Welcome to the Onyxshell Installer!             ${RESET}"
echo -e "${BLUE}====================================================${RESET}"

# 1. System Update
echo -e "\n${BLUE}[*] Updating system packages...${RESET}"
sudo pacman -Syu --noconfirm

# 2. Check and install yay (AUR Helper)
if ! command -v yay &> /dev/null; then
    echo -e "${BLUE}[*] Installing yay AUR helper...${RESET}"
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay-bin
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
    swww
    cava
    gnome-keyring
    libnotify
    pavucontrol
)

AUR_PACKAGES=(
    brave-bin
    wlogout
    pyprland
)

# 4. Install Packages
echo -e "\n${BLUE}[*] Installing official packages...${RESET}"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"

echo -e "\n${BLUE}[*] Installing AUR packages...${RESET}"
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

# 5. Backup Existing Configs
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

# 6. Copy Onyxshell Configs
echo -e "\n${BLUE}[*] Installing Onyxshell configurations...${RESET}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r "$SCRIPT_DIR/config/"* "$CONFIG_DIR/"

# 7. Make Scripts Executable
echo -e "\n${BLUE}[*] Setting execution permissions for scripts...${RESET}"
chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true
# If there are other scripts, add them here
if [ -f "$SCRIPT_DIR/update.sh" ]; then
    chmod +x "$SCRIPT_DIR/update.sh"
fi

echo -e "\n${BLUE}====================================================${RESET}"
echo -e "${GREEN}    Installation Complete!                          ${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo -e "You can now log out and select ${GREEN}Hyprland${RESET} from your Display Manager (like SDDM or GDM)."
echo -e "Enjoy your new Onyxshell setup!"
