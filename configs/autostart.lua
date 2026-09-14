-- ~/.config/hypr/autostart.lua
-- Replaces exec-once = ... from the old .conf

-- Active shell stack from ~/.config/hypr/shell.lua (HM-managed).
local ok, shell = pcall(require, "shell")
if not ok then shell = "waybar" end

hl.on("hyprland.start", function()
    -- waybar (when shell == "waybar") is managed by its systemd user service,
    -- not launched here; DMS runs via its own dms.service either way.
    if shell == "waybar" then
        -- DMS replaces dunst/hypridle and the nm/blueman tray applets.
        hl.exec_cmd("dunst")
        hl.exec_cmd("hypridle")
        hl.exec_cmd("blueman-applet")
        hl.exec_cmd("nm-applet --indicator")
    end
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland")
    hl.exec_cmd("playerctld daemon")
    hl.exec_cmd("systemctl --user start graphical-session.target")
    hl.exec_cmd("[workspace special:obsidian silent] obsidian")
    hl.exec_cmd("[workspace special:telegram silent] Telegram")
end)
