{
  config,
  pkgs,
  lib,
  hyprland,
  self ? null,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared
  ];

  hyperland.enable = true;

  hyperland.hyprland = {
    monitorsFile = ./hyprland-monitors.conf;
    hyprpaperTemplate = ../../configs/hyprpaper-default.conf;
    hyprlockTemplate = ../../configs/hyprlock-default.conf;
    hypridleConfig = ../../configs/hypridle-default.conf;
    scriptsDir = ../../scripts/hyprland;
    useHomeManager = true;
    amd.enable = true;
  };

  hyperland.waybar = {
    enable = true;
    configPath = ../../configs/waybar/config.json;
    stylePath = ../../configs/waybar/style.css;
    scriptsDir = ../../scripts/waybar;
    useHomeManager = true;
  };

  hyperland.services = {
    enable = true;
    openssh.enable = true;
  };

  services.tailscale.enable = true;

  hyperland.packages = {
    enable = true;
    base.enable = true;
    desktop.enable = true;
    dev.enable = true;
  };

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.bluetooth.enable = true;

  fonts.packages = with pkgs; [
    tokyonight-gtk-theme
    papirus-icon-theme
    bibata-cursors
  ];

  xdg.portal.enable = true;
  xdg.portal.wlr.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  system.stateVersion = "25.11";
}
