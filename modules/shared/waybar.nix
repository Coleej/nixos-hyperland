{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hyperland.waybar;
  user = config.hyperland.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
in {
  options.hyperland.waybar = {
    enable = lib.mkEnableOption "Waybar setup and config install";
    useHomeManager = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Home Manager for waybar config files (config.json, style.css)";
    };
    configPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to waybar config JSON";
    };
    stylePath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to waybar CSS";
    };
    scriptsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Directory containing waybar script files";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.waybar];

    systemd.user.services.waybar = {
      description = "Waybar status bar";
      after = ["graphical-session.target"];
      wantedBy = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.waybar}/bin/waybar --config ${userHome}/.config/waybar/config --style ${userHome}/.config/waybar/style.css";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    systemd.user.services.hyperland-waybar-setup = {
      description = "Hyperland: setup Waybar configs in user home";
      wantedBy = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyperland-waybar-setup" ''
          set -euo pipefail
          echo "[hyperland][waybar] setting up Waybar configs"

          mkdir -p ${userHome}/.config/waybar/scripts ${userHome}/.local/bin

          ${lib.optionalString (!cfg.useHomeManager) ''
            ln -sf ${
              if cfg.configPath != null
              then "${cfg.configPath}"
              else "${../../configs/waybar/config.json}"
            } ${userHome}/.config/waybar/config

            ln -sf ${
              if cfg.stylePath != null
              then "${cfg.stylePath}"
              else "${../../configs/waybar/style.css}"
            } ${userHome}/.config/waybar/style.css
          ''}

          ${lib.optionalString (cfg.scriptsDir != null) ''
            cp -f ${cfg.scriptsDir}/*.sh ${userHome}/.config/waybar/scripts/ 2>/dev/null || true
            chmod +x ${userHome}/.config/waybar/scripts/*.sh 2>/dev/null || true
          ''}

          ${lib.optionalString (cfg.scriptsDir == null) ''
            cp -f ${../../scripts/waybar}/*.sh ${userHome}/.config/waybar/scripts/ 2>/dev/null || true
            chmod +x ${userHome}/.config/waybar/scripts/*.sh 2>/dev/null || true
          ''}

          if [ -f ${../../scripts}/rofi-brightness.sh ]; then
            mkdir -p ${userHome}/.local/bin
            install -Dm0755 ${../../scripts}/rofi-brightness.sh ${userHome}/.local/bin/rofi-brightness
          fi

          chown -R ${userName}:${userGroup} ${userHome}/.config/waybar
          echo "[hyperland][waybar] Waybar setup complete"
        '';
      };
    };
  };
}
