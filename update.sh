#!/bin/bash

REPO_DIR="$HOME/onyxshell"

# List of all the config folders inside ~/.config/ that you want to back up
CONFIG_DIRS=(
  "waybar"
  "rofi"
  "wlogout"
  "hypr"
  "pypr"
  "cava"
  "swaync"
  "yazi"
  "theme"
  "quickshell"
  "xdg-desktop-portal"
  "nvim"
  "kitty"
  "fastfetch"
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

# Copy .zshrc separately
echo "📁 Copying .zshrc..."
if [ -f "$HOME/.zshrc" ]; then
  mkdir -p "$REPO_DIR/zsh"
  cp "$HOME/.zshrc" "$REPO_DIR/zsh/.zshrc"
  echo "  ✔️ Copied .zshrc"
else
  echo "  ⚠️ Warning: ~/.zshrc not found on your system, skipping."
fi


# Git operations
echo "🔍 Staging changes..."
git add .

echo "📝 Committing changes..."
# Prompt the user for a commit message
read -p "Enter commit message (or press Enter for default): " CUSTOM_MESSAGE

# Check if the input is empty
if [ -z "$CUSTOM_MESSAGE" ]; then
  # Fallback message if you just press Enter
  COMMIT_MSG="Update configs - $(date +'%Y-%m-%d %H:%M:%S')"
else
  # Use your custom message
  COMMIT_MSG="$CUSTOM_MESSAGE"
fi

git commit -m "$COMMIT_MSG"

echo "☁️ Pushing to GitHub..."
git push origin main 

echo "✅ Done! Everything is safely backed up."