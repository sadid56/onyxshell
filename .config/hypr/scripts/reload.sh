#!/bin/bash
# Script to reload Hyprland, Waybar, SwayNC and other services

# Reload Hyprland config
hyprctl reload

# Restart Quickshell
killall quickshell 2>/dev/null || true
quickshell &

# Restart Hypridle
killall hypridle
hypridle &

# Notify user of completion
notify-send -u low "Desktop Reloaded" "Quickshell, Hypridle, and Hyprland configuration reloaded."
