-- Animated gradient border + dimmed inactive windows, coloured from the current cwal palette.
local colors = {}
for line in io.lines(os.getenv("HOME") .. "/.cache/cwal/colors-hyprland.conf") do
    local n, v = line:match("^%$color(%d+) = (rgb%b())")
    if n then colors[tonumber(n)] = v end
end
hl.config({
    general = {
        border_size = 2,
        col = {
            active_border = { colors = { colors[12], colors[14], colors[13], colors[4] }, angle = 45 },
            inactive_border = "rgba(00000000)",
        },
    },
    decoration = { dim_inactive = true, dim_strength = 0.25 },
})
