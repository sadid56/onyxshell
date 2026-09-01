#!/usr/bin/env bash

# openSUSE Package Installer
# shellcheck disable=SC1091
SCRIPT_DIR_PACKAGES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_PACKAGES/common.sh"

install_opensuse_packages() {
    print_step "Checking and installing openSUSE packages..."

    if confirm "Refresh repositories with zypper?"; then
        sudo zypper refresh
    fi

    local SUSE_PKGS
    read -r -a SUSE_PKGS <<< "$(get_distro_packages "opensuse")"

    print_step "Installing repository packages via zypper..."
    sudo zypper install -y --no-confirm "${SUSE_PKGS[@]}" || true

    print_step "Checking for Quickshell & Matugen on openSUSE..."
    if ! command -v quickshell &>/dev/null; then
        print_info "Quickshell can be built from source or installed via OBS on openSUSE."
    fi
    if ! command -v matugen &>/dev/null && command -v cargo &>/dev/null; then
        if confirm "Install matugen using cargo?"; then
            cargo install matugen || true
        fi
    fi

    print_success "openSUSE package setup completed!"
}
