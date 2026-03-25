#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Images"
HOUR=$(date +%H)

if [ "$HOUR" -lt 12 ]; then
  TYPE="grow"
elif [ "$HOUR" -lt 18 ]; then
  TYPE="wipe"
else
  TYPE="outer"
fi

if ! pgrep -x "awww-daemon" >/dev/null; then
  awww-daemon &
  sleep 0.5
fi

WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \))

if [ -z "$WALLPAPERS" ]; then
  notify-send "Wallpaper Picker" "No wallpapers found"
  exit 1
fi

ROFI_INPUT=""
while IFS= read -r file; do
  ROFI_INPUT+="$(basename "$file")\0icon\x1f$file\n"
done <<<"$WALLPAPERS"

SELECTED_NAME=$(echo -e "$ROFI_INPUT" | rofi -dmenu -i -markup-rows -p "Wallpaper" -theme ~/.config/hypr/styles/wallpaper-picker.rasi)

if [ -n "$SELECTED_NAME" ]; then
  awww img "$WALLPAPER_DIR/$SELECTED_NAME" \
    --transition-type "$TYPE" \
    --transition-pos "$(shuf -i 0-1 -n 1),$(shuf -i 0-1 -n 1)" \
    --transition-step 90 \
    --transition-fps 60 \
    --transition-angle $(shuf -i 0-360 -n 1)
fi
