#!/bin/bash
spawned=false
if ! hyprctl clients | grep -q "class: kitty-dropdown"; then
    kitty --class kitty-dropdown &
    spawned=true
    for i in {1..50}; do
        if hyprctl clients | grep -q "class: kitty-dropdown"; then
            break
        fi
        sleep 0.05
    done
    sleep 0.05
fi

if [ "$spawned" = true ]; then
    if ! hyprctl monitors | grep -q "special:dropdown"; then
        hyprctl dispatch "hl.dsp.workspace.toggle_special('dropdown')"
    fi
else
    # If it was already running, toggle its state
    hyprctl dispatch "hl.dsp.workspace.toggle_special('dropdown')"
fi
