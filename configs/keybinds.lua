-- ~/.config/hypr/keybinds.lua
-- Replaces bind = / bindm = / binde = from the old .conf

local mod = "SUPER"
local terminal = "alacritty"
local menu = "wofi --show drun"
local browser = "firefox"

-- App launchers
hl.bind(mod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + SHIFT + RETURN", hl.dsp.exec_cmd(browser))

-- Window management
hl.bind(mod .. " + Q", hl.dsp.kill_active)
hl.bind(mod .. " + M", hl.dsp.exit)
hl.bind(mod .. " + x", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + V", hl.dsp.togglefloating())
hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + ALT + J", hl.dsp.layout("togglesplit"))

-- DPMS
hl.bind(mod .. " + SHIFT + O", hl.dsp.exec_cmd("hyprctl dispatch dpms off"))
hl.bind(mod .. " + ALT + L", hl.dsp.exec_cmd("hyprctl dispatch dpms on"))

-- Focus
hl.bind(mod .. " + left", hl.dsp.movefocus("l"))
hl.bind(mod .. " + right", hl.dsp.movefocus("r"))
hl.bind(mod .. " + up", hl.dsp.movefocus("u"))
hl.bind(mod .. " + down", hl.dsp.movefocus("d"))

hl.bind(mod .. " + h", hl.dsp.movefocus("l"))
hl.bind(mod .. " + j", hl.dsp.movefocus("d"))
hl.bind(mod .. " + k", hl.dsp.movefocus("u"))
hl.bind(mod .. " + l", hl.dsp.movefocus("r"))

-- Move
hl.bind(mod .. " + SHIFT + h", hl.dsp.movewindow("l"))
hl.bind(mod .. " + SHIFT + j", hl.dsp.movewindow("d"))
hl.bind(mod .. " + SHIFT + k", hl.dsp.movewindow("u"))
hl.bind(mod .. " + SHIFT + l", hl.dsp.movewindow("r"))

-- Workspaces 1..9
for i = 1, 9 do
    hl.bind(mod .. " + " .. i, hl.dsp.workspace(tostring(i)))
    hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.movetoworkspace(tostring(i)))
end

-- Workspace 10
hl.bind(mod .. " + 0", hl.dsp.workspace("10"))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.movetoworkspace("10"))

-- Special workspaces
hl.bind(mod .. " + ALT + S", hl.dsp.togglespecialworkspace("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.movetoworkspace("special:magic"))
hl.bind(mod .. " + ALT + O", hl.dsp.togglespecialworkspace("obsidian"))
hl.bind(mod .. " + ALT + T", hl.dsp.togglespecialworkspace("telegram"))

-- Mouse wheel workspace switch
hl.bind(mod .. " + mouse_down", hl.dsp.workspace("e+1"))
hl.bind(mod .. " + mouse_up", hl.dsp.workspace("e-1"))

-- Mouse drag / resize (replaces bindm = SUPER, mouse:272/273, ...)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshots (no modifier)
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png'))

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Keybind helper
hl.bind(mod .. " + TAB", hl.dsp.exec_cmd("hypr-binds"))