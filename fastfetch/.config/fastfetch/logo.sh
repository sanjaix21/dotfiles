#!/bin/bash
LOGO_DIR="$HOME/Pictures/wallpapers/avatars"

if [ -d "$LOGO_DIR" ] && command -v kitty >/dev/null 2>&1; then
    RANDOM_LOGO=$(find "$LOGO_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" \) | shuf -n 1)
    if [ -n "$RANDOM_LOGO" ]; then
        kitty icat --align center "$RANDOM_LOGO"
    fi
fi
fastfetch --logo none
