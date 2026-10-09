-- hyprwalk: walk around the desktop in 3D (Esc leaves). Restored from the pre-ArchEclipse hyprland.lua.
hl.plugin.load("/home/pisun/hyprwalk/hyprwalk.so")

local function toggle()
    hl.plugin.hyprwalk.toggle()
end

-- While 3D is up, Hyprland's own keybinds are off: this submap holds only the toggle.
hl.define_submap("hyprwalk", function()
    hl.bind("SUPER + grave", toggle)
    -- Leave typing mode (entered with E); same as the plugin's own Super+Esc.
    hl.bind("SUPER + E", function() hl.plugin.hyprwalk.type("off") end)
    -- Width only (the plugin's own wheel resize keeps the aspect).
    local widen = os.getenv("HOME") .. "/.config/hypr/scripts/hyprwalk-widen.sh "
    hl.bind("SUPER + right", function() hl.exec_cmd(widen .. "200") end)
    hl.bind("SUPER + left", function() hl.exec_cmd(widen .. "-200") end)
end)

-- What's resized or floated in 3D is undone on leaving: each window goes back to how it was on entering.
local before = {}
local function snapshot()
    before = {}
    for _, w in ipairs(hl.get_windows()) do
        before[w.address] = { floating = w.floating, at = w.at, size = w.size }
    end
end
local function restore()
    for _, w in ipairs(hl.get_windows()) do
        local b, sel = before[w.address], "address:" .. w.address
        if b and b.floating ~= w.floating then
            hl.dispatch(hl.dsp.window.float({ action = "toggle", window = sel }))
        end
        if b and b.floating then
            hl.dispatch(hl.dsp.window.resize({ x = b.size.x, y = b.size.y, window = sel }))
            hl.dispatch(hl.dsp.window.move({ x = b.at.x, y = b.at.y, window = sel }))
        end
    end
    before = {}
end
hl.bind("SUPER + grave", function()
    snapshot()
    toggle()
    hl.dispatch(hl.dsp.submap("hyprwalk"))
    -- Returns to the normal binds once 3D is left, however it is left.
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/hyprwalk-submap-watch.sh")
end)

-- Windows opened while 3D is up float, so Hyprland's tiling doesn't resize the windows already
-- hanging in the world (a panel is as big as its real window). They are tiled again on leaving 3D.
local floated = {}

hl.on("window.open", function(w)
    if hl.get_current_submap() ~= "hyprwalk" or w.floating then
        return
    end
    floated[w.address] = true
    hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
end)

hl.on("keybinds.submap", function(name)
    if name == "hyprwalk" then
        return
    end
    for _, w in ipairs(hl.get_windows()) do
        if floated[w.address] and w.floating then
            hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
        end
    end
    floated = {}
    restore()
end)
