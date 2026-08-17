#!/bin/bash

set -e

# ====================================================
# Onyxshell Installation Script
# https://github.com/sadid56/onyxshell
# ====================================================

# Colors
GREEN="\033[1;32m"
BLUE="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BOLD="\033[1m"
RESET="\033[0m"

# Auto-yes flag
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
            [Nn]*) echo -e "${YELLOW}[-] Skipped.${RESET}"; return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Distro Detection
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        LIKE=${ID_LIKE:-""}
    else
        echo -e "${RED}[!] Cannot detect OS distribution.${RESET}"
        exit 1
    fi
}

detect_distro

DISTRO_NAME="$(echo "$DISTRO" | awk '{print toupper(substr($0,1,1))tolower(substr($0,2))}')"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}${BOLD}       ❄️  Onyxshell Desktop Setup: ${DISTRO_NAME}  ❄️${RESET}"
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
            echo -e "${YELLOW}[!] Unsupported distro for auto-update. Skipping...${RESET}" ;;
    esac
fi

# =========================
# 2. BASE DEVELOPMENT TOOLS
# =========================
if confirm "Install base build tools (git, curl, zsh, build headers)?"; then
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
# 3. PACKAGES & DEPENDENCIES
# =========================
install_packages() {
    case "$DISTRO" in
        arch|cachyos|endeavouros|manjaro)
            echo -e "${BLUE}[*] Installing packages for Arch-based distribution...${RESET}"
            ARCH_PACKAGES=(
                # Window Manager & Shell
                hyprland hyprlock hypridle hyprshot hyprpicker quickshell awww matugen
                # Terminal & Editor
                kitty neovim fastfetch cava btop
                # Wayland & Clipboard
                wl-clipboard cliphist grim slurp
                # Audio, Media & Brightness
                playerctl brightnessctl wireplumber pipewire-pulse pavucontrol
                # Network & Bluetooth
                network-manager-applet bluez bluez-utils
                # Portals & Polkit
                xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                hyprpolkitagent gnome-keyring libnotify
                # GTK / Qt Theming
                gnome-themes-extra adwaita-icon-theme nwg-look qt6ct qt5ct qt6-svg qt6-declarative
                # System Utilities & Scripting
                zsh nodejs python python-pip fzf jq bc power-profiles-daemon nautilus
                # Fonts
                ttf-jetbrains-mono-nerd noto-fonts-emoji
            )
            sudo pacman -S --needed --noconfirm "${ARCH_PACKAGES[@]}"
            ;;
        fedora)
            echo -e "${BLUE}[*] Installing packages for Fedora...${RESET}"
            FEDORA_PACKAGES=(
                hyprland hyprlock hypridle hyprpicker kitty neovim fastfetch cava btop
                wl-clipboard cliphist grim slurp playerctl brightnessctl wireplumber
                NetworkManager-applet bluez bluez-tools pavucontrol
                xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                gnome-keyring libnotify gnome-themes-extra adwaita-icon-theme qt6ct qt5ct qt6-qtsvg qt6-qtdeclarative
                zsh nodejs python3 fzf jq bc power-profiles-daemon nautilus
                google-noto-emoji-fonts jetbrains-mono-fonts-all
            )
            sudo dnf install -y "${FEDORA_PACKAGES[@]}"
            echo -e "${YELLOW}[!] Note: For Quickshell, Awww, and Matugen on Fedora, install them via Copr, Cargo, or from source if not in repositories.${RESET}"
            ;;
        ubuntu|debian|pop|mint)
            echo -e "${BLUE}[*] Installing packages for Debian/Ubuntu-based distribution...${RESET}"
            DEB_PACKAGES=(
                hyprland kitty neovim cava btop
                wl-clipboard cliphist grim slurp playerctl brightnessctl wireplumber
                network-manager-gnome bluez pavucontrol
                xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
                gnome-keyring libnotify-bin gnome-themes-extra adwaita-icon-theme
                qt6-style-plugins qt5-style-plugins qml6-module-qtquick qml6-module-qtquick-controls
                zsh nodejs python3 fzf jq bc power-profiles-daemon nautilus
                fonts-noto-color-emoji fonts-jetbrains-mono
            )
            sudo apt install -y "${DEB_PACKAGES[@]}"
            echo -e "${YELLOW}[!] Note: Quickshell, Awww, and Matugen may need to be compiled from source or installed via pre-built binaries on Debian/Ubuntu.${RESET}"
            ;;
        *)
            echo -e "${RED}[!] Package list not pre-configured for $DISTRO. Please install dependencies manually.${RESET}"
            ;;
    esac
}

if confirm "Install desktop environment and core packages?"; then
    install_packages
fi

# =========================
# 4. SYSTEM SERVICES
# =========================
if confirm "Enable Power Profiles Daemon & Bluetooth services?"; then
    sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
fi

# =========================
# 5. OH MY ZSH & SHELL
# =========================
if confirm "Install Oh My Zsh + Plugins (Autosuggestions, Syntax Highlighting, Powerlevel10k)?"; then

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo -e "${BLUE}[*] Installing Oh My Zsh...${RESET}"
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo -e "${GREEN}[+] Oh My Zsh already installed.${RESET}"
    fi

    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    mkdir -p "$ZSH_CUSTOM/plugins"
    mkdir -p "$ZSH_CUSTOM/themes"

    # Plugins
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo -e "${BLUE}[*] Installing zsh-autosuggestions...${RESET}"
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo -e "${BLUE}[*] Installing zsh-syntax-highlighting...${RESET}"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi

    # Powerlevel10k Theme
    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        echo -e "${BLUE}[*] Installing Powerlevel10k...${RESET}"
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi

    # Restore .zshrc
    if [ -f "$SCRIPT_DIR/zsh/.zshrc" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            echo -e "${BLUE}[*] Backing up existing ~/.zshrc to ~/.zshrc_backup_${TIMESTAMP}...${RESET}"
            mv "$HOME/.zshrc" "$HOME/.zshrc_backup_${TIMESTAMP}"
        fi
        echo -e "${BLUE}[*] Applying .zshrc from repository...${RESET}"
        cp "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
        echo -e "${GREEN}[+] .zshrc restored successfully.${RESET}"
    fi
fi

# =========================
# 6. COPY CONFIGURATIONS
# =========================
if confirm "Copy configuration files to ~/.config?"; then
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
# 7. ASSETS & DIRECTORIES
# =========================
if confirm "Create standard media folders and install default wallpapers?"; then
    mkdir -p "$HOME/Pictures/Images"
    mkdir -p "$HOME/Pictures/Screenshots"

    if [ -d "$SCRIPT_DIR/.config/quickshell/assets/images" ]; then
        echo -e "${BLUE}[*] Copying default wallpapers to ~/Pictures/Images/...${RESET}"
        cp -r "$SCRIPT_DIR/.config/quickshell/assets/images/"* "$HOME/Pictures/Images/" 2>/dev/null || true
    fi
    echo -e "${GREEN}[+] Pictures directories ready.${RESET}"
fi

# =========================
# 8. SCRIPT PERMISSIONS
# =========================
echo -e "${BLUE}[*] Setting execution permissions for scripts...${RESET}"
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
chmod +x "$HOME/.config/quickshell/scripts/"*.py 2>/dev/null || true
echo -e "${GREEN}[+] Execution permissions applied.${RESET}"

# =========================
# 9. SET DEFAULT SHELL
# =========================
if confirm "Set Zsh as your default shell?"; then
    if [ "$SHELL" != "$(which zsh)" ]; then
        chsh -s "$(which zsh)"
        echo -e "${GREEN}[+] Default shell set to $(which zsh).${RESET}"
    else
        echo -e "${GREEN}[+] Zsh is already default shell.${RESET}"
    fi
fi

echo ""
echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}${BOLD}     🎉  ONYXSHELL INSTALLATION COMPLETE!  🎉        ${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo -e "You can now log out and start your session with ${BOLD}Hyprland${RESET}!"
echo -e "Keybindings cheat sheet: Press ${BOLD}Super + /${RESET} at any time."
