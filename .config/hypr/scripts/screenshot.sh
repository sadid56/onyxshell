#!/bin/bash

# Ensure screenshot directory exists
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

# Run hyprshot with passed arguments
hyprshot "$@" -o "$DIR"
