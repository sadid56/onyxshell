#!/bin/bash

hyprctl reload

killall -9 quickshell qs 2>/dev/null || true
while pgrep -x quickshell >/dev/null || pgrep -x qs >/dev/null; do sleep 0.05; done
hyprctl eval 'hl.exec_cmd("quickshell")'

killall hypridle 2>/dev/null || true
hypridle -c ~/.config/hypr/config/hypridle.conf &

if [ -f ~/.config/hypr/scripts/power_auto.sh ]; then
    killall power_auto.sh 2>/dev/null || true
    ~/.config/hypr/scripts/power_auto.sh &
fi

sleep 0.5
notify-send -u low "Desktop Reloaded" "Configuration reloaded successfully"
