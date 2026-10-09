-- Desktop mode (Super+Shift+D): ordinary floating windows plus a KDE-style panel with the open apps at the bottom (waybar/),
-- and minimize/maximize/close buttons on every floating window (quickshell/windeco, fed by emit_windows below).
-- Leaving it tiles back the windows that were tiled before.
local home = os.getenv("HOME")
local on, floated = false, {}
local deco_file = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/windeco.json"
local deco_timer, deco_last = nil, ""
local qs_deco = "qs -p " .. home .. "/.config/quickshell/windeco"

local function toggle_float(w)
    hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. w.address }))
end

local function fullscreen(w) -- a fullscreen game must stay as it is
    local f = w.fullscreen
    return f == true or (type(f) == "number" and f > 0)
end

-- Apps that draw their own window buttons get no pill (substrings of the window class, lowercase). Add more here.
local own_buttons = { "steam", "spotify", "zen_browser", "firefox", "chrom", "brave", "discord", "vesktop", "telegram", "obsidian", "vinegarhq", "org.gnome.", "code" }

local function draws_own_buttons(w)
    local class = string.lower(tostring(w.class))
    for _, part in ipairs(own_buttons) do
        if string.find(class, part, 1, true) then return true end
    end
    return false
end

-- Hyprland draws no title bars here, so a Quickshell layer puts the buttons on each floating window.
-- This pushes the windows' geometry to it ~30 times a second (written only when something changed).
local function emit_windows()
    local mon = hl.get_active_monitor()
    local visible = { [tostring(mon.active_workspace.name)] = true }
    if mon.active_special_workspace then visible[tostring(mon.active_special_workspace.name)] = true end
    local items = {}
    for _, w in ipairs(hl.get_windows()) do
        if w.mapped and w.floating and w.fullscreen ~= 2 and not draws_own_buttons(w) and w.workspace and visible[tostring(w.workspace.name)] then
            items[#items + 1] = string.format('{"a":"%s","x":%d,"y":%d,"w":%d,"h":%d}', tostring(w.address), w.at.x, w.at.y, w.size.x, w.size.y)
        end
    end
    local json = "[" .. table.concat(items, ",") .. "]"
    if json ~= deco_last then
        deco_last = json
        local f = io.open(deco_file .. ".tmp", "w")
        if f then
            f:write(json)
            f:close()
            os.rename(deco_file .. ".tmp", deco_file)
        end
    end
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
        hl.exec_cmd(qs_deco)
        deco_timer = hl.timer(emit_windows, { timeout = 33, type = "repeat" })
    else
        if deco_timer then
            deco_timer:set_enabled(false)
            deco_timer = nil
        end
        deco_last = ""
        local f = io.open(deco_file, "w")
        if f then
            f:write("[]")
            f:close()
        end
        hl.exec_cmd("pkill -x waybar")
        hl.exec_cmd(qs_deco .. " kill")
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

-- A taskbar click on a normal window switches the workspace underneath; an open scratchpad would keep covering it, so close it.
hl.on("workspace.active", function()
    if on then hl.exec_cmd(home .. "/.config/hypr/scripts/special-close.sh") end
end)
