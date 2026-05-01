#!/bin/bash
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/cliphist-rofi-img"
mkdir -p "$CACHE_DIR"

# Create a blank icon for text entries so they align properly
BLANK_ICON="$CACHE_DIR/blank.png"
if [ ! -f "$BLANK_ICON" ]; then
  convert -size 1x1 xc:transparent "$BLANK_ICON" 2>/dev/null || touch "$BLANK_ICON"
fi

if [ -z "$1" ]; then
  # List items for Rofi
  cliphist list | while read -r line; do
    id="${line%%$'\t'*}"
    content="${line#*$'\t'}"

    if [[ "$line" == *'[[ binary data'* ]]; then
      img_path="$CACHE_DIR/$id.png"
      [ ! -f "$img_path" ] && cliphist decode "$id" >"$img_path" 2>/dev/null

      # Use a non-breaking space as the text so NO number shows
      echo -en " \0icon\x1f$img_path\x1finfo\x1f$id\n"
    else
      # Show ONLY the content, store the ID in the 'info' field
      echo -en "$content\0icon\x1f$BLANK_ICON\x1finfo\x1f$id\n"
    fi
  done
else
  # Use the hidden 'info' field (ROFI_INFO) to decode the correct item
  echo "$ROFI_INFO" | cliphist decode | wl-copy
fi
