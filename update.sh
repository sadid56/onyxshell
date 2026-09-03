#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

# Source colors if available
if [ -f "$SCRIPT_DIR/setup/colors.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/setup/colors.sh"
else
    GREEN="\033[1;32m"
    BLUE="\033[1;34m"
    YELLOW="\033[1;33m"
    RED="\033[1;31m"
    CYAN="\033[1;36m"
    RESET="\033[0m"
    print_step() { echo -e "${BLUE}[+] $1${RESET}"; }
    print_success() { echo -e "${GREEN}[✔️] $1${RESET}"; }
    print_warn() { echo -e "${YELLOW}[!] $1${RESET}"; }
    print_error() { echo -e "${RED}[✗] $1${RESET}"; }
fi

CONFIG_DIRS=(
    "hypr"
    "qs"
    "kitty"
    "fastfetch"
    "cava"
    "nvim"
    "xdg-desktop-portal"
    "fish"
    "matugen"
    "htop"
    "fontconfig"
    "gtk-3.0"
    "gtk-4.0"
    "qt5ct"
    "qt6ct"
    "environment.d"
)

CONFIG_FILES=(
    "starship.toml"
    "kdeglobals"
    "brave-flags.conf"
    "chrome-flags.conf"
    "chromium-flags.conf"
)

echo ""
echo -e "${CYAN}🚀 Starting dotfiles update from ~/.config...${RESET}"
echo ""

if [ ! -d "$REPO_DIR" ]; then
    print_error "Could not find the repository at $REPO_DIR"
    exit 1
fi

print_step "Syncing configuration folders and files..."

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$HOME/.config/$dir" ]; then
        mkdir -p "$REPO_DIR/.config/$dir"
        rsync -av --delete "$HOME/.config/$dir/" "$REPO_DIR/.config/$dir/"
        print_success "Synced $dir"
    else
        print_warn "~/.config/$dir not found on your system, skipping."
    fi
done

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$HOME/.config/$file" ]; then
        cp "$HOME/.config/$file" "$REPO_DIR/.config/$file"
        print_success "Synced $file"
    else
        print_warn "~/.config/$file not found on your system, skipping."
    fi
done

# Ensure compatibility symlink in repository (.config/quickshell -> qs)
rm -rf "$REPO_DIR/.config/quickshell"
ln -sfn "qs" "$REPO_DIR/.config/quickshell"
print_success "Maintained compatibility symlink .config/quickshell -> qs"

# Ensure compiled C binaries are clean in repo
if [ -d "$REPO_DIR/.config/qs/c_tools" ]; then
    (cd "$REPO_DIR/.config/qs/c_tools" && make clean) >/dev/null 2>&1 || true
fi

echo ""
echo -e "${GREEN}✨ Dotfiles synchronization completed successfully!${RESET}"
echo ""
