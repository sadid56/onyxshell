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
        read -rp "$(echo -e "${BLUE}[?] $1 (y/n): ${RESET}")" choice
        case "$choice" in
            [Yy]*) return 0 ;;
            [Nn]*) echo -e "${RED}[-] Skipped.${RESET}"; return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}    Onyxshell + Zsh Full Setup Installer           ${RESET}"
echo -e "${BLUE}====================================================${RESET}"

# =========================
# 1. SYSTEM UPDATE
# =========================
if confirm "Update system packages?"; then
    sudo pacman -Syu --noconfirm
fi

# =========================
# 2. BASE TOOLS
# =========================
if confirm "Install base tools (git, curl, zsh)?"; then
    sudo pacman -S --needed --noconfirm git curl zsh base-devel
fi

# =========================
# 3. YAY INSTALL
# =========================
if ! command -v yay &> /dev/null; then
    if confirm "Install yay AUR helper?"; then
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        cd /tmp/yay-bin
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay-bin
    fi
else
    echo -e "${GREEN}[+] yay already installed${RESET}"
fi

# =========================
# 4. PACKAGES
# =========================
OFFICIAL_PACKAGES=(
    hyprland hyprlock hyprshot kitty yazi rofi waybar swaync
    wl-clipboard cliphist playerctl brightnessctl wireplumber
    network-manager-applet ttf-jetbrains-mono-nerd noto-fonts-emoji
    cava gnome-keyring libnotify pavucontrol
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    gnome-themes-extra adwaita-icon-theme nwg-look qt6ct qt5ct
    fastfetch neovim zsh nodejs npm fzf power-profile-daemon
)

AUR_PACKAGES=(
    brave-bin wlogout pyprland quickshell-overview-git
)

if confirm "Install official packages?"; then
    sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
fi

if confirm "Enable Power Profiles Daemon service?"; then
    sudo systemctl enable --now power-profiles-daemon.service
fi

if confirm "Install AUR packages?"; then
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
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
        git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

    [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]] && \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

    # Theme
    [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]] && \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

    # Restore .zshrc from repo if it exists
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/zsh/.zshrc" ]; then
        echo -e "${BLUE}[*] Restoring .zshrc from repository...${RESET}"
        cp "$SCRIPT_DIR/zsh/.zshrc" "$HOME/.zshrc"
        echo -e "${GREEN}[+] .zshrc restored${RESET}"
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
echo -e "${GREEN}   INSTALLATION COMPLETE 🎉                         ${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo "Restart your terminal or log out and select Hyprland + Zsh ready!"