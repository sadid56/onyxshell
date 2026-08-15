#!/bin/bash
if ! hyprctl clients | grep -q "class: kitty-dropdown"; then
    kitty --class kitty-dropdown &
    sleep 0.25
fi
hyprctl dispatch "hl.dsp.workspace.toggle_special('dropdown')"
