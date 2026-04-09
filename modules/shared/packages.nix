{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hyperland.packages;
in {
  options.hyperland.packages = {
    enable = lib.mkEnableOption "Shared package groups";
    base.enable = lib.mkEnableOption "Common CLI utilities";
    desktop.enable = lib.mkEnableOption "Desktop helpers for Wayland sessions";
    dev.enable = lib.mkEnableOption "Developer toolchain";
    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Additional packages to append to shared packages.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      (lib.optionals cfg.base.enable (with pkgs; [
        htop
        btop
        bottom
        tree
        lsof
        lshw
        fastfetch
        nmap
        zip
        unzip
        gnupg
        curl
        file
        jq
        bat
        fd
        fzf
        ripgrep
        tldr
        whois
        plocate
        less
        eza
        grc
        xdg-utils
      ]))
      ++ (lib.optionals cfg.desktop.enable (with pkgs; [
        alacritty
        kitty
        ghostty
        home-manager
        opencode
        wl-clipboard
        grim
        slurp
        swappy
        dunst
        cliphist
        brightnessctl
        playerctl
        pavucontrol
        bibata-cursors
        hyprpaper
        hypridle
        hyprlock
        wofi
        networkmanagerapplet
        blueman
        libnotify
      ]))
      ++ (lib.optionals cfg.dev.enable (with pkgs; [
        git
        gh
        gcc
        gnumake
        cmake
        binutils
        patchelf
        python3
        go
        nodejs
        yarn
        imagemagick
      ]))
      ++ cfg.extraPackages;
  };
}
