#!/bin/bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"

hyprshot "$@" -o "$DIR"
