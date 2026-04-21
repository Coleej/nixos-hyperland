{
  config,
  pkgs,
  lib,
  self,
  ...
}:
{
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
    ".config/hypr/hyprland-base.conf" = {
      source = self + /configs/hyprland-base.conf;
      force = true;
    };
    ".config/hypr/hyprland.conf" = {
      source = self + /configs/hyprland-default.conf;
      force = true;
    };
    ".config/waybar/config" = {
      source = self + /configs/waybar/config.json;
      force = true;
    };
    ".config/waybar/style.css" = {
      source = self + /configs/waybar/style.css;
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
