{ lib, pkgs, config, ... }:
let
  cfg = config.hyperland.desktop;
in {
  options.hyperland.desktop = {
    enable = lib.mkEnableOption "Shared desktop (Wayland env, portals, fonts, GTK/Qt)";
    fonts.enable = lib.mkEnableOption "Install recommended Nerd/base fonts";
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };

    services.displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "hyprland" "gtk" ];
    };

    fonts.packages = lib.mkIf cfg.fonts.enable (
      with pkgs; [
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        nerd-fonts.hack
        noto-fonts
        noto-fonts-color-emoji
        ubuntu-classic
        liberation_ttf
      ]
    );
  };
}
