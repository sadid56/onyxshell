#!/bin/bash

# Cleanly close all open applications
hyprctl clients -j 2>/dev/null | jq -r '.[].address' | while read -r addr; do
  hyprctl dispatch closewindow address:$addr
done

sleep 0.5

# Immediate poweroff
systemctl poweroff
