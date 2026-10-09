-- Desktop mode (Super+Shift+D): ordinary floating windows plus a KDE-style panel with the open apps at the bottom (waybar/).
-- Leaving it tiles back the windows that were tiled before.
local home = os.getenv("HOME")
local on, floated = false, {}

local function toggle_float(w)
    hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
end

local function fullscreen(w) -- a fullscreen game must stay as it is
    local f = w.fullscreen
    return f == true or (type(f) == "number" and f > 0)
end

local function set_mode(enable)
    on = enable
    if enable then
        for _, w in ipairs(hl.get_windows()) do
            if w.mapped and not w.floating and not fullscreen(w) then
                floated[w.address] = true
                toggle_float(w)
            end
        end
        hl.exec_cmd("waybar -c " .. home .. "/.config/hypr/waybar/config.jsonc -s " .. home .. "/.config/hypr/waybar/style.css")
    else
        hl.exec_cmd("pkill -x waybar")
        for _, w in ipairs(hl.get_windows()) do
            if floated[w.address] and w.floating then
                toggle_float(w)
            end
        end
        floated = {}
    end
end

hl.bind("SUPER + SHIFT + D", function() set_mode(not on) end)

-- New windows float too (3D mode has its own handling, leave it alone).
hl.on("window.open", function(w)
    if on and not w.floating and not fullscreen(w) and hl.get_current_submap() ~= "hyprwalk" then
        floated[w.address] = true
        toggle_float(w)
    end
end)
