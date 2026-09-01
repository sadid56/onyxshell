#!/usr/bin/env bash

setup_display_manager() {
    print_step "Checking for active Display / Login Manager..."

    local detected_dm=""
    local dm_services=("greetd" "sddm" "gdm" "lightdm" "ly" "lemurs" "lxdm" "display-manager")

    for dm in "${dm_services[@]}"; do
        if systemctl is-enabled "${dm}.service" &>/dev/null; then
            detected_dm="$dm"
            break
        fi
    done

    if [ -n "$detected_dm" ]; then
        print_info "Detected active display manager: ${BOLD}${detected_dm}${RESET}. Keeping current setup."
        return 0
    fi

    print_warn "No active display manager detected."
    if confirm "Install and configure Greetd (tuigreet) as your modern terminal greeter?"; then
        print_step "Installing greetd and tuigreet..."

        case "$DISTRO_FAMILY" in
            arch)
                sudo pacman -S --needed --noconfirm greetd greetd-tuigreet || true
                ;;
            fedora)
                sudo dnf install -y greetd greetd-tuigreet || sudo dnf install -y greetd tuigreet || true
                ;;
            opensuse)
                sudo zypper install -y greetd tuigreet || true
                ;;
            *)
                print_warn "Please install greetd and tuigreet manually for your distribution."
                ;;
        esac

        if command -v greetd &>/dev/null || [ -d /etc/greetd ]; then
            sudo mkdir -p /etc/greetd
            sudo tee /etc/greetd/config.toml >/dev/null << 'EOF_GREETD'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd start-hyprland --asterisks"
user = "greeter"
EOF_GREETD

            sudo mkdir -p /etc/systemd/system/greetd.service.d
            sudo tee /etc/systemd/system/greetd.service.d/override.conf >/dev/null << 'EOF_OVERRIDE'
[Service]
Type=idle
StandardInput=tty
StandardOutput=tty
StandardError=journal
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
EOF_OVERRIDE

            sudo systemctl daemon-reload 2>/dev/null || true
            sudo systemctl enable greetd.service 2>/dev/null || true
            print_success "Greetd (tuigreet) successfully configured and enabled!"
        else
            print_warn "Could not configure greetd automatically. You can launch Hyprland via 'start-hyprland' or 'Hyprland'."
        fi
    fi
}
