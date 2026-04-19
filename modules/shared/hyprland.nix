{
  lib,
  pkgs,
  config,
  hyprland ? null,
  ...
}:
let
  cfg = config.hyperland.hyprland;
  user = config.hyperland.user;
  userHome = user.home;
  userName = user.name;
  userGroup = user.group;
  hyprlandPkgs = if hyprland != null then hyprland.packages.${pkgs.stdenv.system} else pkgs;
  hyprpaper = hyprlandPkgs.hyprpaper or null;
  hypridle = hyprlandPkgs.hypridle or null;
  hyprlock = hyprlandPkgs.hyprlock or null;
  defaultWallpaper = ../../wallpapers/default.jpg;
in
{
  options.hyperland.hyprland = {
    enable = lib.mkEnableOption "Hyprland base setup";
    useHomeManager = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Home Manager for hyprland config files (hyprland.conf, hyprland-base.conf, hyprland-monitors.conf)";
    };
    monitorsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Per-host Hyprland monitors config file path";
    };
    wallpaper = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Wallpaper file path for hyprpaper/hyprlock generation";
    };
    hyprpaperTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Template hyprpaper.conf with __WALLPAPER__ placeholder";
    };
    hyprlockTemplate = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Template hyprlock.conf with __WALLPAPER__ placeholder";
    };
    hypridleConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to hypridle.conf to install";
    };
    scriptsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Directory of Hyprland helper scripts to copy and chmod +x";
    };
    amd.enable = lib.mkEnableOption "Enable AMD-specific OpenGL/Vulkan env overrides";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.sessionVariables = lib.mkIf cfg.amd.enable {
      AMD_VULKAN_ICD = "RADV";
      MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
    };

    hardware.graphics.enable32Bit = lib.mkIf cfg.amd.enable true;

    systemd.user.services.hyprvibe-hyprpaper = lib.mkIf (hyprpaper != null) {
      description = "Hyperland: hyprpaper wallpaper daemon";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.writeShellScriptBin "hyprpaper-start" ''
          set -euo pipefail
          RUNDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          pick_wayland_display() {
            if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
              echo "''${WAYLAND_DISPLAY}"
              return 0
            fi
            local sock
            sock="$(ls -1 "$RUNDIR"/wayland-* 2>/dev/null | head -n1 || true)"
            [ -n "$sock" ] || return 1
            basename "$sock"
          }
          pick_hypr_signature() {
            if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
              echo "''${HYPRLAND_INSTANCE_SIGNATURE}"
              return 0
            fi
            local d
            d="$(ls -1d "$RUNDIR"/hypr/* 2>/dev/null | head -n1 || true)"
            [ -n "$d" ] || return 1
            basename "$d"
          }
          for _ in $(seq 1 100); do
            wl="$(pick_wayland_display || true)"
            sig="$(pick_hypr_signature || true)"
            if [ -n "$wl" ] && [ -n "$sig" ] && [ -S "$RUNDIR/hypr/$sig/.socket2.sock" ]; then
              export XDG_RUNTIME_DIR="$RUNDIR"
              export WAYLAND_DISPLAY="$wl"
              export HYPRLAND_INSTANCE_SIGNATURE="$sig"
              exec ${hyprpaper}/bin/hyprpaper --config ${userHome}/.config/hypr/hyprpaper.conf
            fi
            sleep 0.1
          done
          exit 1
        ''}";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    systemd.user.services.hypridle = lib.mkIf (hypridle != null && cfg.hypridleConfig != null) {
      description = "Hyperland: hypridle daemon";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${hypridle}/bin/hypridle --config ${userHome}/.config/hypr/hypridle.conf";
        Restart = "on-failure";
      };
    };

    systemd.user.services.hyprlock = lib.mkIf (hyprlock != null) {
      description = "Hyperland: hyprlock daemon";
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${hyprlock}/bin/hyprlock --config ${userHome}/.config/hypr/hyprlock.conf";
        Restart = "on-failure";
      };
    };

    systemd.user.services.hyperland-setup = {
      description = "Hyperland: setup Hyprland configs in user home";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyperland-setup" ''
          set -euo pipefail
          echo "[hyperland] setting up Hyprland configs"

          WALLPAPER_PATH="${if cfg.wallpaper != null then "${cfg.wallpaper}" else "${defaultWallpaper}"}"

          mkdir -p ${userHome}/.config/hypr
          chmod 755 ${userHome}/.config/hypr

          ${lib.optionalString (!cfg.useHomeManager) ''
            ln -sf ${../../configs/hyprland-base.conf} ${userHome}/.config/hypr/hyprland-base.conf

            ${lib.optionalString (cfg.monitorsFile != null) ''
              ln -sf ${cfg.monitorsFile} ${userHome}/.config/hypr/$(basename ${cfg.monitorsFile})
            ''}

            ln -sf ${../../configs/hyprland-default.conf} ${userHome}/.config/hypr/hyprland.conf
          ''}

          ${lib.optionalString cfg.useHomeManager ''
            rm -f ${userHome}/.config/hypr/hyprland-base.conf ${userHome}/.config/hypr/hyprland.conf ${userHome}/.config/hypr/hyprland-monitors.conf
          ''}

          ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#$WALLPAPER_PATH#g" ${
            if cfg.hyprpaperTemplate != null then
              "${cfg.hyprpaperTemplate}"
            else
              "${../../configs/hyprpaper-default.conf}"
          } > ${userHome}/.config/hypr/hyprpaper.conf

          ${pkgs.gnused}/bin/sed "s#__WALLPAPER__#$WALLPAPER_PATH#g" ${
            if cfg.hyprlockTemplate != null then
              "${cfg.hyprlockTemplate}"
            else
              "${../../configs/hyprlock-default.conf}"
          } > ${userHome}/.config/hypr/hyprlock.conf

          ${lib.optionalString (cfg.hypridleConfig != null) ''
            ln -sf ${cfg.hypridleConfig} ${userHome}/.config/hypr/hypridle.conf
          ''}

          ${lib.optionalString (cfg.scriptsDir != null) ''
            mkdir -p ${userHome}/.config/hypr/scripts
            cp -f ${cfg.scriptsDir}/*.sh ${userHome}/.config/hypr/scripts/ 2>/dev/null || true
            chmod +x ${userHome}/.config/hypr/scripts/*.sh 2>/dev/null || true
          ''}

          chown -R ${userName}:${userGroup} ${userHome}/.config/hypr
          echo "[hyperland] Hyprland setup complete"
        '';
      };
    };
  };
}
