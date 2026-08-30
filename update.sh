#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

CONFIG_DIRS=(
  "hypr"
  "quickshell"
  "kitty"
  "fastfetch"
  "cava"
  "nvim"
  "xdg-desktop-portal"
  "fish"
  "matugen"
  "htop"
  "fontconfig"
  "gtk-3.0"
  "gtk-4.0"
  "qt5ct"
  "qt6ct"
)

CONFIG_FILES=(
  "starship.toml"
  "kdeglobals"
  "chrome-flags.conf"
  "chromium-flags.conf"
)

echo "🚀 Starting dotfiles update from ~/.config..."

if [ ! -d "$REPO_DIR" ]; then
  echo "❌ Error: Could not find the repository at $REPO_DIR"
  exit 1
fi

echo "📁 Syncing configuration folders and files..."

for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    mkdir -p "$REPO_DIR/.config/$dir"
    rsync -av --delete "$HOME/.config/$dir/" "$REPO_DIR/.config/$dir/"
    echo "  ✔️ Synced $dir"
  else
    echo "  ⚠️ Warning: ~/.config/$dir not found on your system, skipping."
  fi
done

for file in "${CONFIG_FILES[@]}"; do
  if [ -f "$HOME/.config/$file" ]; then
    cp "$HOME/.config/$file" "$REPO_DIR/.config/$file"
    echo "  ✔️ Synced $file"
  else
    echo "  ⚠️ Warning: ~/.config/$file not found on your system, skipping."
  fi
done

echo ""
echo "✨ Dotfiles synchronization completed successfully!"
