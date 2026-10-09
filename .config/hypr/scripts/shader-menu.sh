#!/bin/bash
# Pick a screen effect from config/shaders (+ "off"). Any shader stops direct scanout, so switch it off for games.
d=~/.config/hypr/config/shaders
pick=$( { echo off; basename -a "$d"/*.glsl | sed 's/\.glsl$//'; } | fuzzel --dmenu -p "shader " ) || exit 0
[[ $pick == off ]] && file= || file=$d/$pick.glsl
[[ -z $file || -f $file ]] || exit 0
hyprctl eval "hl.config({ decoration = { screen_shader = '$file' } })" >/dev/null
