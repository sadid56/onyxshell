#!/usr/bin/env bash

# Check if Waybar is running
if pgrep -x "waybar" > /dev/null; then
    pkill -x waybar
else
    waybar &
fi
