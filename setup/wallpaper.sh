#!/usr/bin/env bash

setup_wallpapers() {
    print_step "Checking wallpaper collection..."

    if confirm "Install Onyxshell Wallpaper Collection (Recommended)?"; then
        print_step "Downloading and installing curated wallpapers..."
        if command -v curl &>/dev/null; then
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/sadid56/wallpaper/main/install.sh)" || {
                print_warn "Wallpaper script encountered an issue. You can run it later manually."
            }
            print_success "Wallpaper installation completed!"
        else
            print_warn "curl is required to download the wallpaper collection. Please install curl and re-run."
        fi
    fi
}
