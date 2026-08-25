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
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
        LIKE="${ID_LIKE:-}"
    else
        echo -e "${RED}[!] Cannot detect OS distribution.${RESET}"
        exit 1
    fi
}

detect_distro

DISTRO_NAME="$(
    echo "$DISTRO" |
        awk '{print toupper(substr($0,1,1))tolower(substr($0,2))}'
)"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}====================================================${RESET}"
echo -e "${GREEN}${BOLD}       ❄️  Onyxshell Desktop Setup: ${DISTRO_NAME}  ❄️${RESET}"
echo -e "${BLUE}====================================================${RESET}"
echo ""

# ====================================================
# SYSTEM UPDATE
# ====================================================

if confirm "Update system packages?"; then

    case "$DISTRO" in

        arch|cachyos|endeavouros|manjaro)
            sudo pacman -Syu --noconfirm
            ;;

        ubuntu|debian|pop|mint)
            sudo apt update
            sudo apt upgrade -y
            ;;

        fedora)
            sudo dnf upgrade -y
            ;;

        opensuse*|suse)
            sudo zypper refresh
            sudo zypper update -y
            ;;

        *)
            echo -e "${YELLOW}[!] Unsupported distro for auto-update. Skipping...${RESET}"
            ;;

    esac

fi

# ====================================================
# BASE BUILD TOOLS
# ====================================================

if confirm "Install base build tools (git, curl, fish, base-devel)?"; then

    case "$DISTRO" in

        arch|cachyos|endeavouros|manjaro)

            sudo pacman -S --needed --noconfirm \
                git \
                curl \
                fish \
                base-devel \
                rsync
            ;;

        ubuntu|debian|pop|mint)

            sudo apt install -y \
                git \
                curl \
                fish \
                build-essential \
                rsync
            ;;

        fedora)

            sudo dnf install -y \
                git \
                curl \
                fish \
                @development-tools \
                rsync
            ;;

        opensuse*|suse)

            sudo zypper install -y \
                git \
                curl \
                fish \
                -t pattern devel_basis \
                rsync
            ;;

        *)

            echo -e "${YELLOW}[!] Unsupported distro for base tools. Skipping...${RESET}"
            ;;

    esac

fi

# ====================================================
# PACKAGE INSTALLATION
# ====================================================

install_packages() {

    case "$DISTRO" in

        # ------------------------------------------------
        # ARCH BASED
        # ------------------------------------------------

        arch|cachyos|endeavouros|manjaro)

            echo -e "${BLUE}[*] Installing packages for Arch-based distribution via pacman...${RESET}"

            ARCH_PACKAGES=(
                hyprland
                hyprlock
                hypridle
                hyprshot
                hyprpicker
                quickshell
                matugen

                kitty
                neovim
                fastfetch
                cava
                htop
                fish
                starship
                firefox

                wl-clipboard
                cliphist
                grim
                slurp

                playerctl
                brightnessctl

                wireplumber
                pipewire
                pipewire-pulse
                pipewire-alsa
                pavucontrol

                network-manager-applet

                xdg-desktop-portal
                xdg-desktop-portal-hyprland
                xdg-desktop-portal-gtk

                polkit-gnome
                gnome-keyring
                libnotify

                gnome-themes-extra
                adwaita-icon-theme

                nwg-look
                qt6ct
                qt5ct
                qt6-svg
                qt6-declarative

                nodejs
                python
                python-pip

                fzf
                jq

                power-profiles-daemon

                nautilus
                rsync

                ttf-jetbrains-mono-nerd
                noto-fonts-emoji
            )

            sudo pacman -S --needed --noconfirm \
                "${ARCH_PACKAGES[@]}"
            ;;

        # ------------------------------------------------
        # FEDORA
        # ------------------------------------------------

        fedora)

            echo -e "${BLUE}[*] Installing packages for Fedora...${RESET}"

            FEDORA_PACKAGES=(
                hyprland
                hyprlock
                hypridle
                hyprpicker

                kitty
                neovim
                fastfetch
                cava
                htop
                fish
                starship
                firefox

                wl-clipboard
                cliphist
                grim
                slurp

                playerctl
                brightnessctl
                wireplumber

                NetworkManager-applet
                pavucontrol

                xdg-desktop-portal
                xdg-desktop-portal-hyprland
                xdg-desktop-portal-gtk

                polkit-gnome
                gnome-keyring
                libnotify

                gnome-themes-extra
                adwaita-icon-theme

                qt6ct
                qt5ct
                qt6-qtsvg
                qt6-qtdeclarative

                nodejs
                python3

                fzf
                jq

                power-profiles-daemon

                nautilus
                rsync

                google-noto-emoji-fonts
                jetbrains-mono-fonts-all
            )

            sudo dnf install -y \
                "${FEDORA_PACKAGES[@]}"
            ;;

        # ------------------------------------------------
        # DEBIAN / UBUNTU
        # ------------------------------------------------

        ubuntu|debian|pop|mint)

            echo -e "${BLUE}[*] Installing packages for Debian/Ubuntu-based distribution...${RESET}"

            DEB_PACKAGES=(
                hyprland

                kitty
                neovim
                cava
                htop
                fish
                starship
                firefox

                wl-clipboard
                cliphist
                grim
                slurp

                playerctl
                brightnessctl
                wireplumber

                network-manager-gnome
                pavucontrol

                xdg-desktop-portal
                xdg-desktop-portal-hyprland
                xdg-desktop-portal-gtk

                policykit-1-gnome
                gnome-keyring
                libnotify-bin

                gnome-themes-extra
                adwaita-icon-theme

                qt6-style-plugins
                qt5-style-plugins

                qml6-module-qtquick
                qml6-module-qtquick-controls

                nodejs
                python3

                fzf
                jq

                power-profiles-daemon

                nautilus
                rsync

                fonts-noto-color-emoji
                fonts-jetbrains-mono
            )

            sudo apt install -y \
                "${DEB_PACKAGES[@]}"
            ;;

        # ------------------------------------------------
        # UNKNOWN
        # ------------------------------------------------

        *)

            echo -e "${RED}[!] Package list not pre-configured for $DISTRO.${RESET}"
            echo -e "${YELLOW}[!] Please install dependencies manually.${RESET}"
            ;;

    esac
}

if confirm "Install desktop environment and core packages?"; then
    install_packages
fi

# ====================================================
# SERVICES
# ====================================================

if confirm "Enable Power Profiles Daemon & PipeWire Audio services?"; then

    echo -e "${BLUE}[*] Enabling system services...${RESET}"

    sudo systemctl enable --now power-profiles-daemon.service \
        2>/dev/null || true

    echo -e "${BLUE}[*] Enabling PipeWire & WirePlumber audio services for user...${RESET}"

    systemctl --user enable --now \
        pipewire.socket \
        pipewire.service \
        2>/dev/null || true

    systemctl --user enable --now \
        pipewire-pulse.socket \
        pipewire-pulse.service \
        2>/dev/null || true

    systemctl --user enable --now \
        wireplumber.service \
        2>/dev/null || true

fi

# ====================================================
# DEPLOY CONFIGURATION
# ====================================================

if confirm "Deploy Onyxshell configuration files to ~/.config?"; then

    TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

    SOURCE_CONFIG_DIR="$SCRIPT_DIR/.config"
    DEST_CONFIG_DIR="$HOME/.config"

    mkdir -p "$DEST_CONFIG_DIR"

    # ------------------------------------------------
    # SAFETY CHECK
    #
    # Never allow source config directory and destination
    # config directory to be the exact same directory.
    # ------------------------------------------------

    SOURCE_CONFIG_REAL="$(realpath -m "$SOURCE_CONFIG_DIR")"
    DEST_CONFIG_REAL="$(realpath -m "$DEST_CONFIG_DIR")"

    if [ "$SOURCE_CONFIG_REAL" = "$DEST_CONFIG_REAL" ]; then

        echo -e "${RED}[!] SAFETY CHECK FAILED.${RESET}"
        echo -e "${RED}[!] Source and destination .config directories are the same:${RESET}"
        echo -e "    $SOURCE_CONFIG_REAL"
        echo ""
        echo -e "${YELLOW}[!] Configuration deployment has been skipped.${RESET}"
        echo -e "${YELLOW}[!] This prevents backup recursion and same-file corruption.${RESET}"

    elif [ ! -d "$SOURCE_CONFIG_DIR" ]; then

        echo -e "${YELLOW}[!] Source config directory not found:${RESET}"
        echo -e "    $SOURCE_CONFIG_DIR"
        echo -e "${YELLOW}[!] Skipping configuration deployment.${RESET}"

    else

        echo -e "${BLUE}[*] Preparing configuration deployment...${RESET}"

        # ------------------------------------------------
        # IMPORTANT:
        #
        # Create the source list BEFORE creating ANY backup.
        #
        # This prevents:
        #
        #   file_backup_123
        #   file_backup_456
        #
        # from becoming new source items during the same run.
        # ------------------------------------------------

        SOURCE_ITEMS=()

        while IFS= read -r -d '' SRC_ITEM; do
            SOURCE_ITEMS+=("$SRC_ITEM")
        done < <(
            find "$SOURCE_CONFIG_DIR" \
                -mindepth 1 \
                -maxdepth 1 \
                ! -name '*_backup_*' \
                -print0
        )

        # ------------------------------------------------
        # Nothing to deploy
        # ------------------------------------------------

        if [ "${#SOURCE_ITEMS[@]}" -eq 0 ]; then

            echo -e "${YELLOW}[!] No configuration files found to deploy.${RESET}"

        else

            for SRC_ITEM in "${SOURCE_ITEMS[@]}"; do

                item="$(basename "$SRC_ITEM")"

                DEST_ITEM="$DEST_CONFIG_DIR/$item"

                # ------------------------------------------------
                # Resolve actual paths
                # ------------------------------------------------

                SRC_REAL="$(realpath -m "$SRC_ITEM")"
                DEST_REAL="$(realpath -m "$DEST_ITEM")"

                # ====================================================
                # SAME PATH
                # ====================================================

                if [ "$SRC_REAL" = "$DEST_REAL" ]; then

                    echo -e "${YELLOW}[!] $item already exists at the same path. Skipping.${RESET}"

                    continue

                fi

                # ====================================================
                # SAME FILE / SAME DIRECTORY
                #
                # Handles symlink / hardlink / same inode situations.
                # ====================================================

                if [ -e "$SRC_ITEM" ] && [ -e "$DEST_ITEM" ]; then

                    if [ "$SRC_ITEM" -ef "$DEST_ITEM" ]; then

                        echo -e "${YELLOW}[!] $item is already the same file/directory. Skipping.${RESET}"

                        continue

                    fi

                fi

                # ====================================================
                # DIRECTORY
                # ====================================================

                if [ -d "$SRC_ITEM" ]; then

                    # ------------------------------------------------
                    # Existing destination directory
                    # ------------------------------------------------

                    if [ -d "$DEST_ITEM" ]; then

                        BACKUP_DIR="${DEST_ITEM}_backup_${TIMESTAMP}"

                        echo -e "${BLUE}[*] Backing up existing directory:${RESET}"
                        echo -e "    $DEST_ITEM"
                        echo -e "${BLUE}    -> $BACKUP_DIR${RESET}"

                        cp -a -- "$DEST_ITEM" "$BACKUP_DIR"

                    # ------------------------------------------------
                    # Destination exists but is not a directory
                    # ------------------------------------------------

                    elif [ -e "$DEST_ITEM" ]; then

                        BACKUP_PATH="${DEST_ITEM}_backup_${TIMESTAMP}"

                        echo -e "${BLUE}[*] Backing up existing path:${RESET}"
                        echo -e "    $DEST_ITEM"
                        echo -e "${BLUE}    -> $BACKUP_PATH${RESET}"

                        cp -a -- "$DEST_ITEM" "$BACKUP_PATH"

                        rm -rf -- "$DEST_ITEM"

                    fi

                    # ------------------------------------------------
                    # Deploy directory
                    # ------------------------------------------------

                    echo -e "${GREEN}[+] Deploying $item config to ~/.config/$item...${RESET}"

                    mkdir -p -- "$DEST_ITEM"

                    rsync -a --delete \
                        -- "$SRC_ITEM/" "$DEST_ITEM/"

                # ====================================================
                # FILE
                # ====================================================

                elif [ -f "$SRC_ITEM" ]; then

                    # ------------------------------------------------
                    # Existing destination file
                    # ------------------------------------------------

                    if [ -e "$DEST_ITEM" ]; then

                        BACKUP_FILE="${DEST_ITEM}_backup_${TIMESTAMP}"

                        echo -e "${BLUE}[*] Backing up existing file:${RESET}"
                        echo -e "    $DEST_ITEM"
                        echo -e "${BLUE}    -> $BACKUP_FILE${RESET}"

                        cp -a -- "$DEST_ITEM" "$BACKUP_FILE"

                    fi

                    # ------------------------------------------------
                    # Deploy file
                    # ------------------------------------------------

                    echo -e "${GREEN}[+] Deploying $item to ~/.config/$item...${RESET}"

                    mkdir -p -- "$(dirname "$DEST_ITEM")"

                    cp -a -- "$SRC_ITEM" "$DEST_ITEM"

                fi

            done

            echo -e "${GREEN}[+] Configuration deployment completed successfully.${RESET}"

        fi

    fi

fi

# ====================================================
# WALLPAPER DIRECTORIES
# ====================================================

mkdir -p "$HOME/Pictures/wallpapers"
mkdir -p "$HOME/Pictures/Screenshots"

# ====================================================
# WALLPAPERS
# ====================================================

if confirm "Install full dynamic wallpaper collection from repository? (Recommended)"; then

    echo -e "${BLUE}[*] Downloading and installing full wallpaper pack...${RESET}"

    if bash -c "$(curl -fsSL https://raw.githubusercontent.com/sadid56/wallpaper/main/install.sh)"; then

        echo -e "${GREEN}[+] Full wallpaper collection installed successfully.${RESET}"

    else

        echo -e "${YELLOW}[!] Failed to fetch online wallpapers.${RESET}"
        echo -e "${YELLOW}[!] Falling back to default bundled wallpapers...${RESET}"

        if [ -d "$SCRIPT_DIR/.config/quickshell/assets/images" ]; then

            cp -rn \
                "$SCRIPT_DIR/.config/quickshell/assets/images/"* \
                "$HOME/Pictures/wallpapers/" \
                2>/dev/null || true

        fi

    fi

else

    echo -e "${BLUE}[*] Using default bundled wallpapers...${RESET}"

    if [ -d "$SCRIPT_DIR/.config/quickshell/assets/images" ]; then

        cp -rn \
            "$SCRIPT_DIR/.config/quickshell/assets/images/"* \
            "$HOME/Pictures/wallpapers/" \
            2>/dev/null || true

    fi

    echo -e "${GREEN}[+] Default wallpapers deployed.${RESET}"

fi

# ====================================================
# SCRIPT PERMISSIONS
# ====================================================

echo -e "${BLUE}[*] Setting execution permissions for scripts...${RESET}"

chmod +x \
    "$HOME/.config/hypr/scripts/"*.sh \
    2>/dev/null || true

chmod +x \
    "$HOME/.config/quickshell/scripts/"*.py \
    2>/dev/null || true

echo -e "${GREEN}[+] Execution permissions applied.${RESET}"

# ====================================================
# FISH SHELL
# ====================================================

if confirm "Set Fish as your default login shell?"; then

    FISH_PATH="$(command -v fish 2>/dev/null || true)"

    if [ -n "$FISH_PATH" ]; then

        if ! grep -Fxq "$FISH_PATH" /etc/shells; then

            echo "$FISH_PATH" |
                sudo tee -a /etc/shells >/dev/null

        fi

        if [ "$SHELL" != "$FISH_PATH" ]; then

            chsh -s "$FISH_PATH"

            echo -e "${GREEN}[+] Default shell set to $FISH_PATH.${RESET}"

        else

            echo -e "${GREEN}[+] Fish is already your default shell.${RESET}"

        fi

    else

        echo -e "${YELLOW}[!] Fish shell executable not found.${RESET}"

    fi

fi

# ====================================================
# COMPLETE
# ====================================================

echo ""

echo -e "${BLUE}====================================================${RESET}"

echo -e "${GREEN}${BOLD}     🎉  ONYXSHELL INSTALLATION COMPLETE!  🎉     ${RESET}"

echo -e "${BLUE}====================================================${RESET}"

echo -e "You can now log out and start your session with ${BOLD}Hyprland${RESET}!"

echo -e "Keybindings cheat sheet: Press ${BOLD}Super + /${RESET} at any time."

echo ""
