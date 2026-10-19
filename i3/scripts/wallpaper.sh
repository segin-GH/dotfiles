#!/bin/sh
# wallpaper.sh - set one wallpaper spanning every monitor as a single canvas.
#
# usage: wallpaper.sh [image]
#
# With no argument, restores the last wallpaper used (or the first one found
# in ~/Pictures/wallpapers).
#
# feh normally repeats/crops the image on each monitor. --no-xinerama makes it
# treat the whole X screen as one monitor, so the image spans all displays.

set -eu

state="${XDG_CACHE_HOME:-$HOME/.cache}/i3/wallpaper"
wallpaper_dir="$HOME/Pictures/wallpapers"

if [ $# -gt 0 ]; then
    img=$1
else
    img=$(cat "$state" 2>/dev/null || true)
fi

if [ -z "${img:-}" ] || [ ! -f "$img" ]; then
    img=$(find "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
        | sort | head -n 1)
fi

if [ -z "$img" ] || [ ! -f "$img" ]; then
    echo "wallpaper.sh: no wallpaper found" >&2
    exit 1
fi

feh --no-xinerama --bg-fill "$img"

mkdir -p "$(dirname "$state")"
printf '%s\n' "$img" > "$state"
