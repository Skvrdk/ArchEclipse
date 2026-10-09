hl.on("hyprland.start", function()
    hl.exec_cmd("discord")
end)

hl.window_rule({
    match = { class = "discord" },
    workspace = "special:hub silent",
})