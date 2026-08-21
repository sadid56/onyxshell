#!/bin/bash
spawned=false
if ! hyprctl clients | grep -q "class: kitty-dropdown"; then
    kitty --class kitty-dropdown -o background_opacity=1.0 -o background_blur=0 &
    spawned=true
    for i in {1..50}; do
        if hyprctl clients | grep -q "class: kitty-dropdown"; then
            break
        fi
        sleep 0.05
    done
    sleep 0.05
fi

# Turn off background blur and dimming for dropdown terminal
hyprctl eval 'hl.config({ decoration = { dim_special = 0.0, blur = { special = false } } })'

if [ "$spawned" = true ]; then
    if ! hyprctl monitors | grep -q "special:dropdown"; then
        hyprctl dispatch "hl.dsp.workspace.toggle_special('dropdown')"
    fi
else
    hyprctl dispatch "hl.dsp.workspace.toggle_special('dropdown')"
fi
