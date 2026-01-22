#!/usr/bin/env bash
# Get current wallpaper from noctalia and generate pywal colors
WALLPAPER=$(find ~/Pictures/Wallpapers -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) -printf '%T+ %p\n' 2>/dev/null | sort -r | head -1 | cut -d' ' -f2-)
if [ -n "$WALLPAPER" ]; then
    matugen image "$WALLPAPER"
fi
