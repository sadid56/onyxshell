#!/usr/bin/env bash

detect_distro() {
    DISTRO_ID=""
    DISTRO_LIKE=""
    DISTRO_NAME=""
    DISTRO_FAMILY=""
    PKG_MANAGER=""

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_LIKE="${ID_LIKE:-}"
        DISTRO_NAME="${PRETTY_NAME:-$ID}"
    elif [ -f /etc/arch-release ]; then
        DISTRO_ID="arch"
        DISTRO_NAME="Arch Linux"
    elif [ -f /etc/fedora-release ]; then
        DISTRO_ID="fedora"
        DISTRO_NAME="Fedora Linux"
    elif [ -f /etc/SuSE-release ]; then
        DISTRO_ID="opensuse"
        DISTRO_NAME="openSUSE"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
    fi

    # Classify into supported families
    if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == *"arch"* || -f /etc/arch-release ]]; then
        DISTRO_FAMILY="arch"
        PKG_MANAGER="pacman"
    elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" == *"fedora"* || "$DISTRO_ID" == "nobara" ]]; then
        DISTRO_FAMILY="fedora"
        PKG_MANAGER="dnf"
    elif [[ "$DISTRO_ID" == *"suse"* || "$DISTRO_LIKE" == *"suse"* ]]; then
        DISTRO_FAMILY="opensuse"
        PKG_MANAGER="zypper"
    else
        DISTRO_FAMILY="unknown"
    fi

    export DISTRO_ID DISTRO_LIKE DISTRO_NAME DISTRO_FAMILY PKG_MANAGER
}

validate_supported_distro() {
    detect_distro
    print_info "Detected System: ${BOLD}${DISTRO_NAME}${RESET} (Family: ${DISTRO_FAMILY})"

    if [ "$DISTRO_FAMILY" = "unknown" ]; then
        print_error "Onyxshell installer currently supports Arch Linux (and derivatives), Fedora, and openSUSE."
        print_warn "Your distribution '${DISTRO_NAME}' is not automatically recognized."
        if ! confirm "Would you like to continue anyway by selecting a package manager manually?" false; then
            exit 1
        fi

        echo ""
        echo "Please select your distribution base:"
        echo "  1) Arch Linux / Arch-based (pacman)"
        echo "  2) Fedora (dnf)"
        echo "  3) openSUSE (zypper)"
        read -rp "$(echo -e "${CYAN}[?] Select [1-3]: ${RESET}")" choice
        case "$choice" in
            1) DISTRO_FAMILY="arch"; PKG_MANAGER="pacman" ;;
            2) DISTRO_FAMILY="fedora"; PKG_MANAGER="dnf" ;;
            3) DISTRO_FAMILY="opensuse"; PKG_MANAGER="zypper" ;;
            *) print_error "Invalid selection. Exiting."; exit 1 ;;
        esac
    fi
}
