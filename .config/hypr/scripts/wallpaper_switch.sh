#!/bin/bash

# Define your wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/Images"

# Check if swww-daemon is running, if not, start it (you had this in your autostart, but it's good as a fallback)
if ! pgrep -x "swww-daemon" >/dev/null; then
  swww-daemon &
  sleep 0.5
fi

# Get a list of all images in the directory
# We use find to ensure we get absolute paths which Rofi needs for icons
WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname \*.jpg -o -iname \*.jpeg -o -iname \*.png -o -iname \*.gif \))

if [ -z "$WALLPAPERS" ]; then
  notify-send "Wallpaper Picker" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

# Create a string formatted for Rofi: "filename\0icon\x1ffull_path\n"
ROFI_INPUT=""
while IFS= read -r file; do
  filename=$(basename "$file")
  # This specific format tells Rofi to use the file itself as the icon
  ROFI_INPUT+="$filename\0icon\x1f$file\n"
done <<<"$WALLPAPERS"

# Pipe the formatted string into Rofi
# -dmenu reads from stdin
# -theme points to our new visual theme
# -markup-rows allows the special formatting to work
SELECTED_FILE=$(echo -e "$ROFI_INPUT" | rofi -dmenu -i -markup-rows -p "" -theme ~/.config/hypr/styles/wallpaper-picker.rasi)

if [ -n "$SELECTED_FILE" ]; then
  # Construct the full path
  FULL_PATH="$WALLPAPER_DIR/$SELECTED_FILE"

  # Apply using swww with the wipe transition we discussed
  swww img "$FULL_PATH" --transition-type wipe --transition-angle 30 --transition-step 90
fi
