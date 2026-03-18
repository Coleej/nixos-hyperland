{ config, pkgs, lib, hyprland, hyperlandUser ? null, self ? null, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared
  ];

  hyperland.enable = true;

  hyperland.user = {
    name = hyperlandUser.name or "cody";
    group = hyperlandUser.group or "users";
    home = hyperlandUser.home or "/home/${hyperlandUser.name or "cody"}";
    description = hyperlandUser.description or "Cody";
    linger = true;
    extraGroups = hyperlandUser.extraGroups or [ ];
  };

  hyperland.hyprland = {
    monitorsFile = ../../configs/hyprland-monitors.conf;
    hyprpaperTemplate = ../../configs/hyprpaper-default.conf;
    hyprlockTemplate = ../../configs/hyprlock-default.conf;
    hypridleConfig = ../../configs/hypridle-default.conf;
    scriptsDir = ../../scripts/hyprland;
  };

  hyperland.waybar = {
    enable = true;
    configPath = ../../configs/waybar/config.json;
    stylePath = ../../configs/waybar/style.css;
    scriptsDir = ../../scripts/waybar;
  };

  hyperland.shell = {
    enable = true;
    defaultTerminal = "alacritty";
    atuin.enable = true;
  };

  hyperland.services = {
    enable = true;
    openssh.enable = true;
  };

  hyperland.packages = {
    enable = true;
    base.enable = true;
    desktop.enable = true;
    dev.enable = true;
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York";

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.bluetooth.enable = true;

  fonts.packages = with pkgs; [
    tokyonight-gtk-theme
    papirus-icon-theme
    bibata-cursors
  ];

  xdg.portal.enable = true;
  xdg.portal.wlroots.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
