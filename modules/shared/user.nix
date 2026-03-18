{ lib, config, pkgs, ... }:
let
  cfg = config.hyperland.user;
  userSubmodule = { ... }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "cody";
        description = "Primary user name for the host.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "users";
        description = "Primary user group for the host.";
      };
      home = lib.mkOption {
        type = lib.types.str;
        default = "/home/cody";
        description = "Home directory path for the primary user.";
      };
      description = lib.mkOption {
        type = lib.types.str;
        default = "Hyperland User";
        description = "GECOS/description for the primary user.";
      };
      linger = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Keep user services running even when not logged in.";
      };
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional groups to add on top of hyperland base groups.";
      };
      icon = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to user profile picture/icon file.";
      };
    };
  };
in
{
  options.hyperland.user = lib.mkOption {
    type = lib.types.either lib.types.str (lib.types.submodule userSubmodule);
    default = {
      name = "cody";
      group = "users";
      home = "/home/cody";
      description = "Hyperland User";
      linger = true;
      extraGroups = [ ];
    };
    description = "Primary user (string short-form or attribute set).";
    apply = value:
      if lib.isString value then
        { name = value; group = "users"; home = "/home/${value}"; }
      else
        {
          name = value.name;
          group = value.group or "users";
          home = value.home or "/home/${value.name}";
          description = value.description or "Hyperland User";
          linger = value.linger or true;
          extraGroups = value.extraGroups or [ ];
          icon = value.icon or null;
        };
  };

  config = let
    baseGroups = [
      "networkmanager" "wheel" "video" "render" "audio" "i2c" "cdrom"
      "plugdev" "adbusers"
    ];
    finalGroups = lib.unique (baseGroups ++ (cfg.extraGroups or [ ]));
  in {
    users.users."${cfg.name}" = {
      isNormalUser = true;
      shell = pkgs.fish;
      description = cfg.description or "Hyperland User";
      linger = cfg.linger or true;
      extraGroups = finalGroups;
      group = cfg.group;
      home = cfg.home;
    };

    system.activationScripts.setUserIcon = lib.mkIf (cfg.icon != null) ''
      echo "[hyperland][user] setting profile picture for ${cfg.name}..."
      if [ -f "${cfg.icon}" ]; then
        mkdir -p "${cfg.home}"
        cp -f "${cfg.icon}" "${cfg.home}/.face" || true
        chown ${cfg.name}:${cfg.group} "${cfg.home}/.face" || true
      fi
    '';
  };
}
