#!/bin/bash
# Script to reload Hyprland, Waybar, SwayNC and other services

# Reload Hyprland config
hyprctl reload

# Restart Quickshell
killall quickshell
quickshell -p /home/sadid/.config/quickshell/shell.qml &

# Restart Hypridle
killall hypridle
hypridle &

# Notify user of completion
notify-send -u low "Desktop Reloaded" "Quickshell, Hypridle, and Hyprland configuration reloaded."
