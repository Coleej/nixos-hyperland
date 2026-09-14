-- ~/.config/hypr/hyprland.lua
-- Shared Hyprland base — symlinked from configs/hyprland.lua
-- Per-host layout is loaded last via require("monitors")

-- Active shell stack from ~/.config/hypr/shell.lua (HM-managed).
local shellOk, shell = pcall(require, "shell")
if not shellOk then shell = "waybar" end

hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "caps:ctrl_modifier",
        kb_rules = "",
        follow_mouse = 1,
        touchpad = { natural_scroll = true },
        sensitivity = 0.0,
    },
    general = {
        gaps_in = 4,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = {
                colors = {"rgba(33ccffee)", "rgba(00ff99ee)"},
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
        allow_tearing = false,
        env = {
            "XCURSOR_SIZE,24",
            "QT_QPA_PLATFORMTHEME,qt6ct",
        },
    },
    decoration = {
        rounding = 8,
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
        },
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
    },
    master = {
        new_status = "master",
    },
    dwindle = {
        preserve_split = true,
    },
})

require("autostart")
require("window-rules")
require("animations")
require("keybinds")
require("monitors")

-- DankMaterialShell integration. DMS generates ~/.config/hypr/dms/*.lua on
-- first run (Settings → Compositor), so each require is pcall-guarded to
-- survive a fresh login before those files exist.
if shell == "dankshell" then
    hl.layer_rule({ match = { namespace = "dms" }, no_anim = true })
    pcall(require, "dms.colors")
    pcall(require, "dms.layout")
    pcall(require, "dms.outputs")
end