-- Game hub: a hidden workspace that slides over a fullscreen game (Discord lives here).
local mainMod = "SUPER"
--- toggle the hub
hl.bind(mainMod .. " + G", hl.dsp.workspace.toggle_special("hub"))
--- send the focused window to the hub
hl.bind(mainMod .. " + CTRL + G", hl.dsp.window.move({ workspace = "special:hub" }))
