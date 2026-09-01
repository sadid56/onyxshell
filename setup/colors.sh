#!/usr/bin/env bash

# Color and Styling Definitions
GREEN="\033[1;32m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
MAGENTA="\033[1;35m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

# Flags
AUTO_YES=false

init_flags() {
    for arg in "$@"; do
        if [[ "$arg" == "--yes" || "$arg" == "-y" ]]; then
            AUTO_YES=true
        fi
    done
}

print_banner() {
    local distro_str="${1:-Arch Linux / Fedora / openSUSE}"
    echo ""
    echo -e "${CYAN}====================================================${RESET}"
    echo -e "${GREEN}${BOLD}         ❄️   Onyxshell Desktop Setup   ❄️${RESET}"
    echo -e "${DIM}            Target: ${distro_str}${RESET}"
    echo -e "${CYAN}====================================================${RESET}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[+] $1${RESET}"
}

print_success() {
    echo -e "${GREEN}[✔️] $1${RESET}"
}

print_warn() {
    echo -e "${YELLOW}[!] $1${RESET}"
}

print_info() {
    echo -e "${CYAN}[i] $1${RESET}"
}

print_error() {
    echo -e "${RED}[✗] $1${RESET}"
}

confirm() {
    local prompt_msg="$1"
    local default_yes="${2:-true}"

    if $AUTO_YES; then
        return 0
    fi

    local prompt_suffix="[Y/n]"
    if [ "$default_yes" = false ]; then
        prompt_suffix="[y/N]"
    fi

    while true; do
        read -rp "$(echo -e "${CYAN}[?] ${prompt_msg} ${prompt_suffix}: ${RESET}")" choice
        if [ -z "$choice" ]; then
            if [ "$default_yes" = true ]; then
                return 0
            else
                echo -e "${YELLOW}[-] Skipped.${RESET}"
                return 1
            fi
        fi

        case "$choice" in
            [Yy]*) return 0 ;;
            [Nn]*)
                echo -e "${YELLOW}[-] Skipped.${RESET}"
                return 1
                ;;
            *) echo -e "${YELLOW}Please answer yes or no.${RESET}" ;;
        esac
    done
}
