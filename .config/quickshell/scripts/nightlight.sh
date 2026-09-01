#!/usr/bin/env bash
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:$PATH"

ACTION="$1"
ARG="$2"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprsunset_${USER}.state"

HYPRSUNSET_BIN="$(which hyprsunset 2>/dev/null || echo "$HOME/.local/bin/hyprsunset")"

ensure_daemon() {
    if ! pgrep -x hyprsunset >/dev/null 2>&1; then
        setsid "$HYPRSUNSET_BIN" -i >/dev/null 2>&1 &
        for i in {1..20}; do
            if hyprctl hyprsunset identity >/dev/null 2>&1; then
                break
            fi
            sleep 0.05
        done
    fi
}

case "$ACTION" in
    on)
        VAL="${ARG:-50}"
        TEMP=$(( 6500 - (VAL * 40) ))
        ensure_daemon
        hyprctl hyprsunset temperature "$TEMP" >/dev/null 2>&1
        echo "$VAL" > "$STATE_FILE"
        ;;
    off)
        hyprctl hyprsunset identity >/dev/null 2>&1 || true
        pkill -x hyprsunset 2>/dev/null || true
        rm -f "$STATE_FILE"
        ;;
    set)
        VAL="${ARG:-50}"
        TEMP=$(( 6500 - (VAL * 40) ))
        ensure_daemon
        hyprctl hyprsunset temperature "$TEMP" >/dev/null 2>&1
        echo "$VAL" > "$STATE_FILE"
        ;;
    status)
        if [ -f "$STATE_FILE" ] && pgrep -x hyprsunset >/dev/null 2>&1; then
            echo "on"
        else
            echo "off"
        fi
        ;;
    get)
        if [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        else
            echo "50"
        fi
        ;;
    *)
        echo "Usage: $0 {on [0-100]|off|set <0-100>|status|get}"
        ;;
esac
