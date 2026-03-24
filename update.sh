#!/bin/bash

REPO_DIR="$HOME/onyxshell"

# List of all the config folders inside ~/.config/ that you want to back up
CONFIG_DIRS=(
  "waybar"
  "rofi"
  "wlogout"
  "hypr"
  "cava"
  "swaync"
  "yazi"
)

echo "🚀 Starting dotfiles update..."

# Check if the repository folder exists
if [ ! -d "$REPO_DIR" ]; then
  echo "❌ Error: Could not find the repository at $REPO_DIR"
  exit 1
fi

echo "📁 Copying configuration folders..."

# Loop through the list and copy each folder to the repo
for dir in "${CONFIG_DIRS[@]}"; do
  # Check if the config directory actually exists on your system
  if [ -d "$HOME/.config/$dir" ]; then
    # Create the target directory in the repo
    mkdir -p "$REPO_DIR/.config/$dir"
    # Copy the contents over
    cp -r "$HOME/.config/$dir/"* "$REPO_DIR/.config/$dir/"
    echo "  ✔️ Copied $dir"
  else
    echo "  ⚠️ Warning: ~/.config/$dir not found on your system, skipping."
  fi
done

# Handle the 'theme' folder
# (Assuming your themes are in ~/.themes. If they are in ~/.local/share/themes, change this path!)
THEME_DIR="$HOME/.themes"
if [ -d "$THEME_DIR" ]; then
  mkdir -p "$REPO_DIR/.themes"
  cp -r "$THEME_DIR/"* "$REPO_DIR/.themes/"
  echo "  ✔️ Copied themes"
else
  echo "  ⚠️ Warning: Theme directory $THEME_DIR not found, skipping."
fi

# Navigate into the repository
cd "$REPO_DIR" || exit

# Git operations
echo "🔍 Staging changes..."
git add .

echo "📝 Committing changes..."
COMMIT_MSG="Update configs: waybar, rofi, wlogout, hypr, theme, cava, swaync, yazi - $(date +'%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MSG"

echo "☁️ Pushing to GitHub..."
git push origin main 

echo "✅ Done! Everything is safely backed up."