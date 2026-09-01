#!/usr/bin/env bash

install_dotfiles() {
    local script_dir="$1"
    local backup_dir="$HOME/.config/onyxshell_backup_$(date +%Y%m%d_%H%M%S)"

    local CONFIG_ITEMS=(
        hypr quickshell kitty fastfetch cava nvim
        xdg-desktop-portal fish matugen htop
        fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct
        starship.toml kdeglobals
        brave-flags.conf chrome-flags.conf chromium-flags.conf
    )

    print_step "Preparing Onyxshell dotfiles installation..."

    if confirm "Backup existing configurations to ${backup_dir} and deploy Onyxshell dotfiles?"; then
        mkdir -p "$backup_dir"
        mkdir -p "$HOME/.config"

        local backup_count=0
        for item in "${CONFIG_ITEMS[@]}"; do
            if [ -e "$HOME/.config/$item" ]; then
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

        # Ensure executable permissions for scripts
        chmod +x "$HOME/.config/hypr/scripts/"* 2>/dev/null || true
        chmod +x "$HOME/.config/quickshell/scripts/"* 2>/dev/null || true

        # Refresh font cache if fontconfig was installed
        if [ -f "$HOME/.config/fontconfig/fonts.conf" ] || command -v fc-cache &>/dev/null; then
            print_step "Refreshing font cache..."
            fc-cache -fv &>/dev/null || true
        fi

        print_success "Dotfiles successfully installed!"
    fi
}
