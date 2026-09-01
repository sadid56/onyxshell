#!/usr/bin/env bash

# Arch Linux Package Installer
# shellcheck disable=SC1091
SCRIPT_DIR_PACKAGES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_PACKAGES/common.sh"

install_arch_packages() {
    print_step "Checking and installing Arch Linux packages..."

    if confirm "Update system repositories with pacman?"; then
        sudo pacman -Syu --noconfirm
    fi

    local ARCH_PKGS
    read -r -a ARCH_PKGS <<< "$(get_distro_packages "arch")"

    print_step "Installing official repository packages via pacman..."
    sudo pacman -S --needed --noconfirm "${ARCH_PKGS[@]}"

    print_success "Arch Linux package setup completed!"
}
