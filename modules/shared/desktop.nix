{
  lib,
  pkgs,
  config,
  ...
}: let
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

    # greetd is a minimal Wayland-capable display/login manager; tuigreet is a
    # TUI greeter that runs inside it. `--cmd Hyprland` makes tuigreet exec
    # Hyprland (not a getty/login shell) after a successful password entry.
    services.greetd = {
      enable = true;
      restart = true;
      settings.default_session = {
        user = "greeter";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
      };
    };

    # greetd runs the greeter as a dedicated, unprivileged user so the
    # kiosk-mode login screen has no extra privileges and PAM can be locked
    # down independently of the real user. isSystemUser (not isNormalUser)
    # because uid < 1000 is reserved for system accounts.
    users.users.greeter = {
      isSystemUser = true;
      uid = 400;
      home = "/var/run/greetd";
      group = "greeter";
      description = "greetd greeter user";
    };
    users.groups.greeter = {};

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      config.common.default = [
        "hyprland"
        "gtk"
      ];
    };

    fonts.packages = lib.mkIf cfg.fonts.enable (
      with pkgs; [
        fira-code
        fira-code-symbols
        font-awesome
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
