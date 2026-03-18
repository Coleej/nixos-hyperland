{ lib, config, ... }:
let
  cfg = config.hyperland;
in
{
  options.hyperland.enable = lib.mkEnableOption "Enable the Hyperland desktop experience";

  imports = [
    ./packages.nix
    ./desktop.nix
    ./hyprland.nix
    ./waybar.nix
    ./shell.nix
    ./services.nix
    ./system.nix
    ./user.nix
  ];

  config = lib.mkIf cfg.enable {
    documentation.man.enable = false;
    hyperland.desktop = {
      enable = true;
      fonts.enable = true;
    };
    hyperland.hyprland.enable = true;
    hyperland.waybar.enable = true;
    hyperland.shell.enable = true;
    hyperland.services = {
      enable = true;
      openssh.enable = true;
    };
    hyperland.system.enable = true;
    hyperland.packages = {
      enable = true;
      base.enable = true;
      desktop.enable = true;
    };
  };
}
