#!/bin/bash

# Define variables
hyprdir=$HOME/.config/hypr
monitor=$1
wallpaper=$2 # This is passed as an argument to the script

case $wallpaper in */wallpaper-engine/*) exec "$hyprdir/wallpaper-daemon/wpe.sh" run "$monitor" "$wallpaper" ;; esac
# Stop any running mpvpaper instance on this monitor when switching to static wallpaper
# (kill first: fast, avoids a 1s stale video under the new static wallpaper)
for pid in $(pgrep -x mpvpaper); do
    if tr '\0' ' ' < "/proc/$pid/cmdline" | grep -F -q "$monitor"; then
        kill "$pid" 2>/dev/null
    fi
done

# Apply wallpaper directly (hyprpaper 0.8+ no longer requires preload)
hyprctl hyprpaper wallpaper "$monitor,$wallpaper"
pkill -x linux-wallpaper # a Wallpaper Engine wallpaper was showing; killed only now so the static one is already there

sleep 0.3 # Brief settle to avoid stuttering (was 1s: dominated switch latency)

# Set wallpaper theme
"$hyprdir/theme/scripts/wal-theme.sh" "$wallpaper"
