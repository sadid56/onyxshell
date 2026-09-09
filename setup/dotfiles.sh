#!/usr/bin/env bash

install_dotfiles() {
    local script_dir="$1"
    local backup_dir="$HOME/.config/onyxshell_backup_$(date +%Y%m%d_%H%M%S)"

    local CONFIG_ITEMS=(
        hypr qs kitty fastfetch cava nvim
        xdg-desktop-portal fish matugen htop
        fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct environment.d
        autostart
        starship.toml kdeglobals kdeglobals.hyprland
        dolphinrc kwalletrc
        brave-origin-flags.conf chrome-flags.conf code-flags.conf
    )

    print_step "Preparing Onyxshell dotfiles installation..."

    if confirm "Backup existing configurations to ${backup_dir} and deploy Onyxshell dotfiles?"; then
        mkdir -p "$backup_dir"
        mkdir -p "$HOME/.config"

        local backup_count=0
        for item in "${CONFIG_ITEMS[@]}"; do
            if [ -e "$HOME/.config/$item" ] || [ -L "$HOME/.config/$item" ]; then
                mv "$HOME/.config/$item" "$backup_dir/"
                echo -e "  ${YELLOW}[*] Backed up $item${RESET}"
                backup_count=$((backup_count + 1))
            fi
        done

        if [ "$backup_count" -gt 0 ]; then
            print_success "Backed up ${backup_count} item(s) to ${backup_dir}"
        fi

        print_step "Copying Onyxshell dotfiles to ~/.config/..."
        cp -r "$script_dir/.config/"* "$HOME/.config/"

        # Ensure default wallpaper exists if current_wallpaper is missing or invalid
        if [ ! -s "$HOME/.config/qs/current_wallpaper" ] || [ ! -f "$(cat "$HOME/.config/qs/current_wallpaper" 2>/dev/null)" ]; then
            echo "$HOME/.config/qs/assets/images/default-wallpaper.png" > "$HOME/.config/qs/current_wallpaper"
        fi

        # Ensure local color-schemes directory exists for Matugen
        mkdir -p "$HOME/.local/share/color-schemes"

        # Set Dolphin as default file manager for directories
        if command -v xdg-mime &>/dev/null; then
            xdg-mime default org.kde.dolphin.desktop inode/directory 2>/dev/null || true
        fi

        # Generate initial dynamic color palette with Matugen
        if command -v matugen &>/dev/null; then
            local def_wp
            def_wp="$(cat "$HOME/.config/qs/current_wallpaper" 2>/dev/null)"
            if [ -n "$def_wp" ] && [ -f "$def_wp" ]; then
                print_step "Generating dynamic color palette with Matugen..."
                matugen image "$def_wp" --source-color-index 0 -t scheme-content -m dark >/dev/null 2>&1 || true
            fi
        fi

        # Ensure executable permissions for scripts
        chmod +x "$HOME/.config/hypr/scripts/"* 2>/dev/null || true
        chmod +x "$HOME/.config/qs/scripts/"* 2>/dev/null || true

        # Build native C tools suite
        if [ -d "$HOME/.config/qs/c_tools" ]; then
            print_step "Compiling native C performance suite..."
            (cd "$HOME/.config/qs/c_tools" && make clean && make) || print_warn "Failed to compile C tools. Ensure gcc and make are installed."
        fi

        # Refresh font cache if fontconfig was installed
        if [ -f "$HOME/.config/fontconfig/fonts.conf" ] || command -v fc-cache &>/dev/null; then
            print_step "Refreshing font cache..."
            fc-cache -fv &>/dev/null || true
        fi

        print_success "Dotfiles successfully installed!"
    fi
}
