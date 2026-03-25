#!/bin/bash

# Close all Hyprland windows
hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
  hyprctl dispatch closewindow address:$addr
done

# Wait a bit to let apps close cleanly
sleep 2

# Shutdown system
systemctl poweroff
