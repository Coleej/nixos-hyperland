{pkgs, ...}: {
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
  ];

  # Lets uv's own downloaded Python builds (and other prebuilt, dynamically
  # linked binaries for generic Linux) execute at all -- NixOS has no
  # standard dynamic-linker path by default and blocks them with a
  # "stub-ld" error otherwise. Kept deliberately limited to uv/Python
  # development needs; add more libraries here as specific tools need them.
  programs.nix-ld = {
    enable = true;
    libraries = [pkgs.zlib pkgs.stdenv.cc.cc.lib];
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
