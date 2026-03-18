{ lib, pkgs, config, ... }:
let
  cfg = config.hyperland.system;
in {
  options.hyperland.system = {
    enable = lib.mkEnableOption "Enable shared system/kernel performance settings";
    kernelPackages = lib.mkOption {
      type = lib.types.nullOr lib.types.unspecified;
      default = pkgs.linuxPackages_zen;
      description = "Kernel packages to use. Defaults to Zen kernel. Set to null to use system default.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = cfg.kernelPackages;

    services.fstrim = {
      enable = true;
      interval = "weekly";
    };

    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };

    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    powerManagement = {
      enable = true;
      cpuFreqGovernor = "performance";
    };
  };
}
