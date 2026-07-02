{
  lib,
  pkgs,
  ...
}: {
  # NixOS-WSL host. The nixos-wsl module (added in flake.nix) supplies the
  # kernel, bootloader, and root filesystem — so there is deliberately no
  # hardware-configuration.nix, no boot loader, and no boot.kernelPackages here.
  # This host does not import modules/shared (the Hyprland desktop stack); it is
  # headless and terminal-only.

  wsl.enable = true;
  wsl.defaultUser = "cody";

  networking.hostName = "wsl";

  services.tailscale.enable = true;

  # cody is created by wsl.defaultUser; just set the login shell and grant sudo.
  users.users.cody = {
    shell = pkgs.fish;
    extraGroups = ["wheel" "docker"];
  };
  programs.fish.enable = true;

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
    # python3 gives uv a nix-built interpreter to use directly, so it never
    # falls back to downloading its own standalone build — those are generic
    # dynamically-linked binaries that can't execute on NixOS (see stub-ld).
    python3
    stdenv.cc.cc.lib
  ];

  # Needed for compiled Python extensions (numpy, scipy, etc.) that dlopen
  # libstdc++.so.6 at runtime instead of linking it via a Nix store RPATH.
  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib];
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Chicago";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05";
}
