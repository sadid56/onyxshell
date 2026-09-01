#!/usr/bin/env bash

setup_user_shell() {
    local fish_path
    fish_path="$(command -v fish 2>/dev/null || true)"

    if [ -z "$fish_path" ]; then
        print_warn "Fish shell is not installed. Skipping shell change."
        return 0
    fi

    if [ "$SHELL" = "$fish_path" ]; then
        print_info "Fish is already your default shell."
        return 0
    fi

    if confirm "Set Fish as your default user shell?"; then
        if ! grep -q "$fish_path" /etc/shells; then
            print_step "Adding ${fish_path} to /etc/shells..."
            echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
        fi

        if chsh -s "$fish_path" "$USER"; then
            print_success "Default shell changed to Fish!"
        else
            print_warn "Could not change shell automatically. You can run 'chsh -s $(which fish)' manually."
        fi
    fi
}
