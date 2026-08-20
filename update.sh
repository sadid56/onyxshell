#!/bin/bash

# ====================================================
# Onyxshell Dotfiles Sync & Update Script
# https://github.com/sadid56/onyxshell
# ====================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$SCRIPT_DIR"

# List of config folders inside ~/.config/ to sync
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
)

# List of standalone config files inside ~/.config/ to sync
CONFIG_FILES=(
  "starship.toml"
)

echo "🚀 Starting dotfiles update from ~/.config..."

# Check if the repository folder exists
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
    mkdir -p "$REPO_DIR/.config"
    cp "$HOME/.config/$file" "$REPO_DIR/.config/$file"
    echo "  ✔️ Synced $file"
  else
    echo "  ⚠️ Warning: ~/.config/$file not found on your system, skipping."
  fi
done

# Clean cache files
find "$REPO_DIR" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$REPO_DIR" -name ".DS_Store" -delete 2>/dev/null || true

# Git operations
cd "$REPO_DIR"
echo "🔍 Checking for changes..."

if [ -z "$(git status --porcelain)" ]; then
  echo "✨ No changes detected. Everything is already up to date!"
  exit 0
fi

echo "📝 Staging changes..."
git add .

read -rp "Enter commit message (or press Enter for default): " CUSTOM_MESSAGE
if [ -z "$CUSTOM_MESSAGE" ]; then
  COMMIT_MSG="chore: update configs - $(date +'%Y-%m-%d %H:%M:%S')"
else
  COMMIT_MSG="$CUSTOM_MESSAGE"
fi

git commit -m "$COMMIT_MSG"

echo "☁️ Pushing to GitHub..."
git push origin main

echo "✅ Done! Everything is safely backed up and pushed."
