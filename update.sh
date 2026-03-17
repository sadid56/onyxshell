#!/bin/bash

# Update the local files from ~/.config to onyxshell first
cp -r ~/.config/hypr ./config/
cp -r ~/.config/waybar ./config/
cp -r ~/.config/rofi ./config/
cp -r ~/.config/wlogout ./config/
cp -r ~/.config/cava ./config/
cp -r ~/.config/swaync ./config/
cp -r ~/.config/theme ./config/


# Git workflow
git add .
echo "What did you change? (Commit message):"
read msg
git commit -m "$msg"
git push origin main

echo "Onyxshell updated successfully!"
