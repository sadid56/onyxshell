#!/bin/bash

# Prompt confirmation to prevent accidental shutdowns
if command -v zenity >/dev/null 2>&1; then
    if ! zenity --question --title="Power Off" --text="Are you sure you want to close all applications and shut down?" --ok-label="Power Off" --cancel-label="Cancel" --width=360 2>/dev/null; then
        exit 0
    fi
fi

hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
  hyprctl dispatch closewindow address:$addr
done

sleep 1

systemctl poweroff
