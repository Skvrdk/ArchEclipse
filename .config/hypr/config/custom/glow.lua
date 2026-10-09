-- Glowing border + dim inactive; colours follow the wallpaper/Spotify palette (scripts/glow.lua).
hl.animation({ leaf = "borderangle", enabled = true, speed = 80, bezier = "linear", style = "loop" })
dofile(os.getenv("HOME") .. "/.config/hypr/scripts/glow.lua")
local s = os.getenv("HOME") .. "/.config/hypr/scripts/"
hl.bind("SUPER + F9", hl.dsp.exec_cmd(s .. "shader-menu.sh"))
hl.bind("SUPER + F10", hl.dsp.exec_cmd(s .. "spotify-theme.sh toggle"))
hl.on("hyprland.start", function() hl.exec_cmd(s .. "spotify-theme.sh") end)
-- The NuPhy's F-row is media keys unless Fn is held, so the shader menu also lives on a letter key.
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(s .. "shader-menu.sh"))
-- Layout per workspace: dwindle -> master -> monocle (see scripts/workspace-mode.sh).
hl.bind("SUPER + TAB", hl.dsp.exec_cmd(s .. "workspace-mode.sh"))
