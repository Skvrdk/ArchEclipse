#!/bin/bash
# Colour the desktop from the Spotify cover of the playing track. `toggle` switches it off/on (off = back to the wallpaper palette).
flag=~/.cache/spotify-theme.off
glow() { hyprctl eval 'dofile(os.getenv("HOME") .. "/.config/hypr/scripts/glow.lua")' >/dev/null; }
if [[ ${1:-} == toggle ]]; then
    if [[ -e $flag ]]; then rm "$flag"; notify-send -t 1500 Theme "Spotify colours on"
    else touch "$flag"; ~/.config/hypr/theme/scripts/wal-theme.sh >/dev/null 2>&1; glow; notify-send -t 1500 Theme "Wallpaper colours"; fi
    exit
fi
# shortcut: one cover file reused, no cache; Spotify only. Upgrade if you want other players.
playerctl -p spotify --follow metadata mpris:artUrl 2>/dev/null | while read -r url; do
    [[ -e $flag || $url != http* ]] && continue
    curl -sf "$url" -o /tmp/spotify-cover.jpg || continue
    ~/.config/hypr/theme/scripts/wal-theme.sh /tmp/spotify-cover.jpg >/dev/null 2>&1 && glow
done
