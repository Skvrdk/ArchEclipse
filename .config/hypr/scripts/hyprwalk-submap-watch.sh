#!/bin/sh
# Started when hyprwalk's 3D view is toggled on: waits until 3D is left (Esc is handled inside the
# plugin and never reaches Hyprland's binds), then gives the normal keybinds back.
# shortcut: polls the plugin state, since hyprwalk has no "left 3D" event; replace with one if it gains it.
sleep 0.6
while hyprctl hyprwalk status 2>/dev/null | grep -qv '"mode": "off"'; do
    sleep 0.3
done
hyprctl dispatch 'hl.dsp.submap("reset")' >/dev/null 2>&1
