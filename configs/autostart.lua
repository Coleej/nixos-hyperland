-- ~/.config/hypr/autostart.lua
-- Replaces exec-once = ... from the old .conf

hl.on("hyprland.start", function()
    -- waybar is managed by the systemd user service (hyperland.waybar module),
    -- not launched here, to avoid duplicate/racing instances.
    hl.exec_cmd("dunst")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("playerctld daemon")
    hl.exec_cmd("systemctl --user start graphical-session.target")
    hl.exec_cmd("[workspace special:obsidian silent] obsidian")
    hl.exec_cmd("[workspace special:telegram silent] telegram-desktop")
end)