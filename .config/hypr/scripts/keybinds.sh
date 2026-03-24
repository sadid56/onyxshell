#!/bin/bash

# Path to your Hyprland config
CONF_FILE="$HOME/.config/hypr/keybinds.conf"

# Read the config, grab the binds, and format them into a perfect monospace table
grep -E '^bind[a-z]*\s*=' "$CONF_FILE" |
  sed 's/bind[a-z]*\s*=\s*//' |
  awk -F ',' '{
        # Trim leading/trailing whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", $1);
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        gsub(/^[ \t]+|[ \t]+$/, "", $3);
        gsub(/^[ \t]+|[ \t]+$/, "", $4);
        
        # Format the output with exact column widths
        if ($4 != "") {
            printf "%-15s   %-12s   %s %s\n", $1, $2, $3, $4;
        } else {
            printf "%-15s   %-12s   %s\n", $1, $2, $3;
        }
    }' |
  column -t -s '' |
  rofi -dmenu -i -p "Keybinds" -theme ~/.config/hypr/styles/keybinds.rasi
