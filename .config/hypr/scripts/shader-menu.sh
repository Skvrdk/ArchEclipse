#!/bin/bash
# Two-step menu: pick where (screen / wallpaper), then the shader. Screen shaders: config/shaders/*.glsl (post-process);
# wallpaper shaders: config/shaders/wall/*.glsl (Shadertoy format, run by papertoy). Any screen shader stops direct scanout: off for games.
d=~/.config/hypr/config/shaders
# Dark popup in the current cwal palette (follows the wallpaper / Spotify colours).
hex() { local c; c=$(grep -m1 "^\$$1 = " ~/.cache/cwal/colors-hyprland.conf | tr -dc '0-9,'); IFS=, read -r r g b <<<"$c"; printf '%02x%02x%02x' "$r" "$g" "$b"; }
bg=$(hex background); fg=$(hex foreground); ac=$(hex color12)
cfg=${XDG_RUNTIME_DIR:-/tmp}/shader-menu-fuzzel.ini
cat >"$cfg" <<INI
[main]
font=JetBrainsMono Nerd Font:size=13
width=26
lines=9
horizontal-pad=26
vertical-pad=20
inner-pad=10
line-height=28
layer=overlay
[colors]
background=${bg}f2
text=${fg}ff
prompt=${ac}ff
input=${fg}ff
match=${ac}ff
placeholder=${fg}80
selection=${ac}ff
selection-text=${bg}ff
selection-match=${bg}ff
border=${ac}ff
[border]
width=2
radius=18
[dmenu]
exit-immediately-if-empty=no
INI
menu() { local in n; in=$(cat); n=$(wc -l <<<"$in"); fuzzel --config "$cfg" --dmenu --lines $(( n < 9 ? n : 9 )) -p "󰹑  $1  " <<<"$in"; }
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
    if [[ $pick == off ]]; then # put the workspace's own wallpaper back (the shader replaced it, and Wallpaper Engine ones were stopped)
        ws=$(hyprctl activeworkspace -j | jq -r .id)
        w=$(grep "^w-$ws=" ~/.config/hypr/wallpaper-daemon/config/HDMI-A-1/defaults.conf | cut -d= -f2-) # shortcut: one monitor
        [[ -f $w ]] && ~/.config/hypr/wallpaper-daemon/hyprpaper.sh HDMI-A-1 "$w" >/dev/null 2>&1
        exit 0
    fi
    [[ -f $d/wall/$pick.glsl ]] || exit 0
    # shim: papertoy would otherwise sit below the bar's reserved area (see scripts-c/zone-1.c)
    LD_PRELOAD=$HOME/.config/hypr/scripts-c/zone-1.so setsid papertoy --frame-rate 30 "$d/wall/$pick.glsl" >/dev/null 2>&1 &
fi
