local terminal = "kitty"

hl.on("hyprland.start", function()
    hl.exec_cmd(terminal .. " btop", { workspace = "5 silent" })
    -- Plugins don't persist across logins; load them without `hyprctl reload` (that one loops, see config/exec.lua).
    hl.exec_cmd("hyprpm reload -n")
    -- systemd keeps the session id of an earlier login (KDE/Halley), so the polkit agent can't register; refresh and restart it.
    hl.exec_cmd("systemctl --user import-environment XDG_SESSION_ID XDG_SESSION_PATH XDG_SESSION_DESKTOP XDG_SESSION_TYPE; systemctl --user reset-failed hyprpolkitagent; systemctl --user restart hyprpolkitagent")
    -- Display off after 15 min, sleep after 2 h (see ~/.config/hypr/hypridle.conf).
    hl.exec_cmd("hypridle")
    -- Gamepad as mouse and shell control; quiet while a game is focused (see the script's header).
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/gamepad-desktop.py")
end)
