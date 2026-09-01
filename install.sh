#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source setup modules
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/colors.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/detect.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/packages/arch.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/packages/fedora.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/packages/opensuse.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/dotfiles.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/display_manager.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/shell.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/setup/wallpaper.sh"

# Help flag handling
show_help() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -y, --yes      Automatic yes to all prompts (non-interactive mode)"
    echo "  -h, --help     Show this help message and exit"
    echo ""
    echo "Supported Distributions:"
    echo "  - Arch Linux & Arch-based derivatives (EndeavourOS, Manjaro, CachyOS, etc.)"
    echo "  - Fedora & Fedora-based derivatives"
    echo "  - openSUSE (Tumbleweed & Leap)"
    echo ""
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
    esac
done

# Initialize arguments & flags
init_flags "$@"

# 1. Distro Detection & Validation
validate_supported_distro

# 2. Display Banner
print_banner "$DISTRO_NAME"

# 3. Install System Packages
case "$DISTRO_FAMILY" in
    arch)
        install_arch_packages
        ;;
    fedora)
        install_fedora_packages
        ;;
    opensuse)
        install_opensuse_packages
        ;;
    *)
        print_warn "Skipping automatic package installation for unrecognized distribution."
        ;;
esac

# 4. Backup & Deploy Dotfiles
install_dotfiles "$SCRIPT_DIR"

# 5. Display Manager / Login Manager Setup
setup_display_manager

# 6. Default User Shell Configuration
setup_user_shell

# 7. Recommended Wallpaper Pack Installation
setup_wallpapers

# 8. Completion Message
echo ""
echo -e "${GREEN}${BOLD}====================================================${RESET}"
echo -e "${GREEN}${BOLD}      🎉   Onyxshell Installation Complete!  🎉${RESET}"
echo -e "${GREEN}${BOLD}====================================================${RESET}"
echo -e "${CYAN}Reboot your system or start Hyprland to enjoy Onyxshell!${RESET}"
echo ""
