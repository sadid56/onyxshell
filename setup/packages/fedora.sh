#!/usr/bin/env bash

# Fedora Package Installer
# shellcheck disable=SC1091
SCRIPT_DIR_PACKAGES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR_PACKAGES/common.sh"

install_fedora_packages() {
    print_step "Checking and installing Fedora packages..."

    if confirm "Update system repositories with dnf?"; then
        sudo dnf upgrade --refresh -y
    fi

    if ! dnf repolist 2>/dev/null | grep -qi "rpmfusion"; then
        if confirm "Enable RPM Fusion free/nonfree repositories (Recommended for multimedia & fonts)?"; then
            sudo dnf install -y \
                https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
                https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || true
        fi
    fi

    local FEDORA_PKGS
    read -r -a FEDORA_PKGS <<< "$(get_distro_packages "fedora")"

    print_step "Installing repository packages via dnf..."
    sudo dnf install -y --skip-broken "${FEDORA_PKGS[@]}"

    print_step "Checking for Quickshell & Matugen on Fedora..."
    if ! command -v quickshell &>/dev/null; then
        print_info "Quickshell can be installed via COPR, cargo, or prebuilt binaries on Fedora."
    fi
    if ! command -v matugen &>/dev/null && command -v cargo &>/dev/null; then
        if confirm "Install matugen using cargo?"; then
            cargo install matugen || true
        fi
    fi

    print_success "Fedora package setup completed!"
}
