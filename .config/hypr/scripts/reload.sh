#!/bin/bash

hyprctl reload

killall -9 quickshell 2>/dev/null || true
while pgrep -x quickshell >/dev/null; do sleep 0.05; done
quickshell &

killall hypridle 2>/dev/null || true
hypridle -c ~/.config/hypr/config/hypridle.conf &

notify-send -u low "Desktop Reloaded" "Quickshell, Hypridle, and Hyprland configuration reloaded."
