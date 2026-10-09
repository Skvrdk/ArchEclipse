#!/bin/bash
# Two-step menu: pick where (screen / wallpaper), then the shader. Screen shaders: config/shaders/*.glsl (post-process);
# wallpaper shaders: config/shaders/wall/*.glsl (Shadertoy format, run by papertoy). Any screen shader stops direct scanout: off for games.
d=~/.config/hypr/config/shaders
menu() { fuzzel --dmenu -p "$1 "; }
list() { { echo off; basename -a "$1"/*.glsl | sed 's/\.glsl$//'; }; }
where=$(printf 'screen\nwallpaper\n' | menu where) || exit 0
if [[ $where == screen ]]; then
    pick=$(list $d | menu screen) || exit 0
    file=$d/$pick.glsl; [[ $pick == off ]] && file=
    [[ -z $file || -f $file ]] || exit 0
    # `time` only advances on full redraws, which costs GPU: enable them just for animated shaders.
    damage=2; [[ -n $file ]] && grep -q 'uniform float time' "$file" && damage=0
    hyprctl eval "hl.config({ debug = { damage_tracking = $damage }, decoration = { screen_shader = '$file' } })" >/dev/null
else
    pick=$(list $d/wall | menu wallpaper) || exit 0
    pkill -x papertoy; pkill -x linux-wallpaper
    [[ $pick == off || ! -f $d/wall/$pick.glsl ]] && exit 0
    # shim: papertoy would otherwise sit below the bar's reserved area (see scripts-c/zone-1.c)
    LD_PRELOAD=$HOME/.config/hypr/scripts-c/zone-1.so setsid papertoy --frame-rate 30 "$d/wall/$pick.glsl" >/dev/null 2>&1 &
fi
