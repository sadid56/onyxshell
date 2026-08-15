#!/bin/bash

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/cliphist-rofi-img"
mkdir -p "$CACHE_DIR"

if [ -z "$1" ]; then
  cliphist list | while read -r line; do
    id="${line%%$'\t'*}"
    if [[ "$line" == *'[[ binary data'* ]]; then
      img_path="$CACHE_DIR/$id.png"
      if [ ! -f "$img_path" ]; then
        cliphist decode "$id" >"$img_path" 2>/dev/null
      fi
      echo -en "$id\t\0icon\x1f$img_path\n"
    else
      echo -en "$line\0icon\x1ftext-x-generic\n"
    fi
  done
else
  # Handle the selection (copy back to clipboard)
  echo "$1" | cliphist decode | wl-copy
fi
