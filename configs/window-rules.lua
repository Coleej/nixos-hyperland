-- ~/.config/hypr/window-rules.lua
-- Replaces windowrule = / windowrulev2 = from the old .conf

hl.window_rule({
    match = { initial_class = "obsidian" },
    workspace = "special:obsidian",
    silent = true,
})

hl.window_rule({
    match = { initial_class = "org.telegram.desktop" },
    workspace = "special:telegram",
    silent = true,
})