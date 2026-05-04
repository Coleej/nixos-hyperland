{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.hyperland.gaming;
in
{
  options.hyperland.gaming = {
    enable = lib.mkEnableOption "Gaming setup (Steam, Gamescope, vulkan-tools)";
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;

    hardware.steam-hardware.enable = true;

    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
      mangohud
    ];

    programs.gamemode.enable = true;

    boot.kernelParams = [ "gamemode" ];

    networking.firewall.trustedInterfaces = [ "steam" ];

    networking.firewall.allowedUDPPorts = [
      27031
      27036
    ];
    networking.firewall.allowedTCPPorts = [
      27036
      27037
    ];
  };
}
