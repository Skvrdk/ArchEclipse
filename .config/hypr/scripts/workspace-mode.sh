#!/bin/bash
# Cycle the layout of the current workspace: dwindle (tiles) -> master -> monocle (one full-screen window at a time), like Halley's cluster layouts.
modes=(dwindle master monocle)
ws=$(hyprctl activeworkspace -j | jq -r .id)
f=~/.cache/workspace-mode-$ws
cur=$(cat "$f" 2>/dev/null || echo dwindle)
for i in "${!modes[@]}"; do [[ ${modes[$i]} == "$cur" ]] && next=${modes[$(( (i + 1) % ${#modes[@]} ))]}; done
echo "${next:-dwindle}" >"$f"
hyprctl eval "hl.workspace_rule({ workspace = '$ws', layout = '${next:-dwindle}' })" >/dev/null
notify-send -t 1200 "Workspace $ws" "${next:-dwindle}"
