#!/bin/bash
# Script to reload Hyprland, Waybar, SwayNC and other services

# Reload Hyprland config
hyprctl reload

# Restart Waybar
killall waybar
waybar &

# Restart SwayNC (Sway Notification Center)
killall swaync
swaync &

# Restart Hypridle
killall hypridle
hypridle &

# Notify user of completion
notify-send -u low "Desktop Reloaded" "Waybar, SwayNC, Hypridle, and Hyprland configuration reloaded."
