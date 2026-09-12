#!/usr/bin/env bash

# Colloid Icon Theme Installer
# shellcheck disable=SC1091

setup_icons() {
    print_step "Checking icon theme..."

    if [ -d "$HOME/.local/share/icons/Colloid-Dark" ] || [ -d "/usr/share/icons/Colloid-Dark" ]; then
        print_success "Colloid icon theme is already installed!"
        return 0
    fi

    if confirm "Clone and install Colloid icon theme from GitHub (Recommended)?"; then
        local temp_dir
        temp_dir="$(mktemp -d)"
        print_step "Cloning Colloid icon theme repository..."
        if git clone --depth 1 https://github.com/vinceliuice/Colloid-icon-theme.git "$temp_dir/Colloid-icon-theme"; then
            print_step "Installing Colloid icons into ~/.local/share/icons..."
            (
                cd "$temp_dir/Colloid-icon-theme" || exit 1
                ./install.sh -d "$HOME/.local/share/icons"
            )
            rm -rf "$temp_dir"

            if command -v gtk-update-icon-cache &>/dev/null; then
                print_step "Updating GTK icon cache..."
                gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Colloid" >/dev/null 2>&1 || true
                gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Colloid-Dark" >/dev/null 2>&1 || true
                gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Colloid-Light" >/dev/null 2>&1 || true
            fi
            print_success "Colloid icon theme installed successfully!"
        else
            print_warn "Failed to clone Colloid icon theme. You can install it manually from https://github.com/vinceliuice/Colloid-icon-theme.git"
            rm -rf "$temp_dir"
        fi
    fi
}
