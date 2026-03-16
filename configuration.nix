{ config, pkgs, ... }:

{
  imports = [];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "nixos";

  i18n.defaultLocale = "en_US.UTF-8";

  time.timeZone = "America/New_York";

  services.xserver.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  security.polkit.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  users.users.cody = {
    isNormalUser = true;
    description = "cody";
    extraGroups = [ "wheel" "docker" "video" "seat" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    hyprland
    dunst
    waybar
    wofi
    brightnessctl
    playerctl
    networkmanagerapplet
    blueman
    libnotify
    rofi-wayland
    grim
    slurp
    wl-clipboard
    xdg-utils
    xdg-user-dirs
    pamixer
  ];

  programs.foot = {
    enable = true;
  };

  xdg.portal.enable = true;
  xdg.portal.wlroots.enable = true;

  system.stateVersion = "24.05";
}
