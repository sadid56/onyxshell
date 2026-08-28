#!/bin/bash

hyprctl reload

killall -9 quickshell qs 2>/dev/null || true
while pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null; do sleep 0.05; done
QUICKSHELL_RELOAD=1 quickshell &

killall hypridle 2>/dev/null || true
hypridle -c ~/.config/hypr/config/hypridle.conf &

if [ -f ~/.config/hypr/scripts/power_auto.sh ]; then
    killall power_auto.sh 2>/dev/null || true
    ~/.config/hypr/scripts/power_auto.sh &
fi

notify-send -u low "Desktop Reloaded" "Quickshell, Hypridle, and Hyprland configuration reloaded."
