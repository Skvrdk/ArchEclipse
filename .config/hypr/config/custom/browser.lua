hl.on("hyprland.start", function()
    hl.exec_cmd("flatpak run app.zen_browser.zen")
end)

hl.window_rule({
    match = { class = "app.zen_browser.zen" },
    workspace = "2 silent",
})