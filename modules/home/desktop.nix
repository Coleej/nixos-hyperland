{
  config,
  pkgs,
  lib,
  self,
  hostName,
  ...
}: let
  monitorsFile =
    {
      thinkpad = self + /hosts/thinkpad/monitors.lua;
      amd-workstation = self + /hosts/amd-workstation/monitors.lua;
    }
    .${
      hostName
    } or (throw "No monitors.lua for host: ${hostName}");
in {
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  programs.alacritty = {
    enable = true;
  };

  programs.wofi = {
    enable = true;
    settings = {
      allow_markup = true;
      insensitive = true;
    };
  };

  programs.hypr-binds = {
    enable = true;
    settings = {
      launcher = {
        app = "wofi";
      };
    };
  };

  home.file = {
    ".config/hypr/hyprland.lua" = {
      source = self + /configs/hyprland.lua;
      force = true;
    };
    ".config/hypr/autostart.lua" = {
      source = self + /configs/autostart.lua;
      force = true;
    };
    ".config/hypr/window-rules.lua" = {
      source = self + /configs/window-rules.lua;
      force = true;
    };
    ".config/hypr/animations.lua" = {
      source = self + /configs/animations.lua;
      force = true;
    };
    ".config/hypr/keybinds.lua" = {
      source = self + /configs/keybinds.lua;
      force = true;
    };
    ".config/hypr/monitors.lua" = {
      source = monitorsFile;
      force = true;
    };
    ".config/waybar/config" = {
      source = self + /configs/waybar/config.json;
      force = true;
    };
    ".config/waybar/style.css" = {
      source = self + /configs/waybar/cyberpunk.css;
      force = true;
    };
    ".config/wofi/style.css" = {
      source = self + /configs/wofi-style.css;
      force = true;
    };
    ".config/alacritty/alacritty.toml".text = ''
      [font]
      size = 12

      [font.normal]
      family = "FiraCode Nerd Font"
    '';
  };
}
