#!/bin/bash
# Hide the open special workspace (scratchpad terminal / hub), if any: used in desktop mode so a taskbar click is not left hidden behind it.
name=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .specialWorkspace.name')
[[ -n $name ]] && hyprctl dispatch "hl.dsp.workspace.toggle_special(\"${name#special:}\")" >/dev/null
