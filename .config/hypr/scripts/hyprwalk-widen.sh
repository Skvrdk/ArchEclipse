#!/bin/sh
# Make the window under the hyprwalk crosshair wider/narrower by $1 pixels, height unchanged.
aimed=$(hyprctl hyprwalk status | jq -c '.aimed | select(.kind == "window")')
[ -n "$aimed" ] || exit 0
hyprctl clients -j | jq -r --argjson a "$aimed" --argjson d "$1" \
    'first(.[] | select(.class == $a.class and .title == $a.title)) | "\(.address) \([.size[0] + $d, 300] | max) \(.size[1])"' |
    { read -r addr w h && hyprctl hyprwalk window "$addr" size "$w" "$h"; }
