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

confirm() {
    if $AUTO_YES; then
        return 0
    fi

    while true; do
        read -rp "$(echo -e "${BLUE}[?] $1 [Y/n]: ${RESET}")" choice
        choice="${choice:-y}"
        case "$choice" in
            [Yy]*) return 0 ;;
            [Nn]*) echo -e "${RED}[-] Skipped.${RESET}"; return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Distro Detection
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        LIKE=$ID_LIKE
    else
        echo -e "${RED}[!] Cannot detect OS distribution.${RESET}"
        exit 1
    fi
}

# Detect Distro
detect_distro

# Format distro name for display (e.g., arch -> Arch, ubuntu -> Ubuntu)
DISTRO_NAME="$(echo "$DISTRO" | awk '{print toupper(substr($0,1,1))tolower(substr($0,2))}')"

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}    Install Onyxshell on ${DISTRO_NAME}${RESET}"
echo -e "${BLUE}====================================================${RESET}\n"

# =========================
# 1. SYSTEM UPDATE
# =========================
if confirm "Update system packages?"; then
    case "$DISTRO" in
        arch|cachyos|endeavouros|manjaro)
            sudo pacman -Syu --noconfirm ;;
        ubuntu|debian|pop|mint)
            sudo apt update && sudo apt upgrade -y ;;
        fedora)
            sudo dnf upgrade -y ;;
        opensuse*|suse)
            sudo zypper refresh && sudo zypper update -y ;;
        *)
            echo -e "${RED}[!] Unsupported distro for auto-update.${RESET}" ;;
    esac
fi

# =========================
# 2. BASE TOOLS
# =========================
if confirm "Install base tools (git, curl, zsh, build tools)?"; then
    case "$DISTRO" in
        arch|cachyos|endeavouros|manjaro)
            sudo pacman -S --needed --noconfirm git curl zsh base-devel ;;
        ubuntu|debian|pop|mint)
            sudo apt install -y git curl zsh build-essential ;;
        fedora)
            sudo dnf install -y git curl zsh @development-tools ;;
        opensuse*|suse)
            sudo zypper install -y git curl zsh -t pattern devel_basis ;;
    esac
fi

# =========================
# 4. PACKAGES
# =========================
install_packages() {
    case "$DISTRO" in
        arch|cachyos|endeavouros|manjaro)
            OFFICIAL_PACKAGES=(
                hyprland hyprlock hyprshot hypridle hyprpicker kitty
                wl-clipboard cliphist playerctl brightnessctl wireplumber
                network-manager-applet ttf-jetbrains-mono-nerd noto-fonts-emoji awww
                cava gnome-keyring libnotify pavucontrol
                xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                gnome-themes-extra adwaita-icon-theme nwg-look qt6ct qt5ct
                fastfetch neovim zsh nodejs fzf power-profiles-daemon hyprpolkitagent nautilus quickshell matugen
            )
            sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
            ;;
        ubuntu|debian|pop|mint)
            DEB_PACKAGES=(
                hyprland kitty wl-clipboard cliphist playerctl brightnessctl wireplumber
                network-manager-gnome fonts-noto-color-emoji
                cava gnome-keyring libnotify-bin pavucontrol
                xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                gnome-themes-extra adwaita-icon-theme qt6-style-plugins qt5-style-plugins
                neovim zsh nodejs fzf power-profiles-daemon nautilus
            )
            sudo apt install -y "${DEB_PACKAGES[@]}"
            ;;
        fedora)
            FEDORA_PACKAGES=(
                hyprland hyprlock hypridle hyprpicker kitty
                wl-clipboard cliphist playerctl brightnessctl wireplumber
                network-manager-applet google-noto-emoji-fonts
                cava gnome-keyring libnotify pavucontrol
                xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                gnome-themes-extra adwaita-icon-theme qt6ct qt5ct
                fastfetch neovim zsh nodejs fzf power-profiles-daemon nautilus
            )
            sudo dnf install -y "${FEDORA_PACKAGES[@]}"
            ;;
        *)
            echo -e "${RED}[!] Package list not pre-configured for $DISTRO. Please install dependencies manually.${RESET}"
            ;;
    esac
}

if confirm "Install desktop and core packages?"; then
    install_packages
fi

if confirm "Enable Power Profiles Daemon service?"; then
    sudo systemctl enable --now power-profiles-daemon.service || true
fi

# =========================
# 5. OH MY ZSH INSTALL
# =========================
if confirm "Install Oh My Zsh + plugins?"; then

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${BLUE}[*] Installing Oh My Zsh...${RESET}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo -e "${GREEN}[+] Oh My Zsh already installed${RESET}"
    fi

    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

    mkdir -p "$ZSH_CUSTOM/plugins"
    mkdir -p "$ZSH_CUSTOM/themes"

    # Plugins
    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]] && \
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

    # Theme
    [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] && \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

    # Restore .zshrc from repo if it exists
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/zsh/.zshrc" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            echo -e "${BLUE}[*] Backing up existing ~/.zshrc to ~/.zshrc_backup_${TIMESTAMP}...${RESET}"
            mv "$HOME/.zshrc" "$HOME/.zshrc_backup_${TIMESTAMP}"
        fi
        echo -e "${BLUE}[*] Restoring .zshrc from repository...${RESET}"
        cp "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
        echo -e "${GREEN}[+] .zshrc restored${RESET}"
    fi
fi

# =========================
# 6. COPY CONFIGURATION FILES
# =========================
if confirm "Copy configuration files to ~/.config?"; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

    mkdir -p "$HOME/.config"

    if [ -d "$SCRIPT_DIR/.config" ]; then
        for SRC_DIR in "$SCRIPT_DIR/.config"/*; do
            if [ -d "$SRC_DIR" ]; then
                dir=$(basename "$SRC_DIR")
                DEST_DIR="$HOME/.config/$dir"

                if [ -d "$DEST_DIR" ]; then
                    BACKUP_DIR="${DEST_DIR}_backup_${TIMESTAMP}"
                    echo -e "${BLUE}[*] Backing up existing $DEST_DIR to $BACKUP_DIR...${RESET}"
                    mv "$DEST_DIR" "$BACKUP_DIR"
                fi

                echo -e "${GREEN}[+] Copying $dir config to ~/.config/$dir...${RESET}"
                cp -r "$SRC_DIR" "$DEST_DIR"
            fi
        done
    fi
fi

# =========================
# 7. DEFAULT SHELL
# =========================
if confirm "Set Zsh as default shell?"; then
    chsh -s "$(which zsh)"
fi

# =========================
# 8. HYPR SCRIPTS PERMISSION
# =========================
if confirm "Make Hypr scripts executable?"; then
    chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
fi

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}    INSTALLATION COMPLETE 🎉                         ${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo "Restart your terminal or log out and select Hyprland + Zsh!"
