#!/bin/bash
# Script for cliphist image previews in rofi-wayland

# Cache directory for thumbnails
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/cliphist-rofi-img"
mkdir -p "$CACHE_DIR"

if [ -z "$1" ]; then
  # List items for Rofi
  cliphist list | while read -r line; do
    id="${line%%$'\t'*}"
    if [[ "$line" == *'[[ binary data'* ]]; then
      # Generate a thumbnail if it doesn't exist
      img_path="$CACHE_DIR/$id.png"
      if [ ! -f "$img_path" ]; then
        cliphist decode "$id" >"$img_path" 2>/dev/null
      fi
      # Send to Rofi with the icon path
      echo -en "$line\0icon\x1f$img_path\n"
    else
      # Send standard text entries
      echo -en "$line\n"
    fi
  done
else
  # Handle the selection (copy back to clipboard)
  echo "$1" | cliphist decode | wl-copy
fi
