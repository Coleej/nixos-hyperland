{pkgs, ...}: {
  # NixOS-WSL host. The nixos-wsl module (added in flake.nix) supplies the
  # kernel, bootloader, and root filesystem — so there is deliberately no
  # hardware-configuration.nix, no boot loader, and no boot.kernelPackages here.
  # This host does not import modules/shared's desktop stack (hyprland/waybar/
  # desktop/gaming); it is headless and terminal-only. It does import
  # packages.nix directly for the shared dev toolchain (gnumake, cmake, etc.).
  imports = [../../modules/shared/packages.nix];

  hyperland.packages = {
    enable = true;
    base.enable = true;
    dev.enable = true;
  };

  wsl.enable = true;
  wsl.defaultUser = "cody";
  # Default is false ("use the existing registration") because NixOS-WSL
  # assumes Windows' own boot sequence already registers the WSLInterop
  # binfmt_misc handler before systemd takes over as PID 1. On this host that
  # inherited registration never happens (/proc/sys/fs/binfmt_misc has no
  # WSLInterop entry), so .exe files (e.g. surge_stat.exe) can't run from WSL
  # without this.
  wsl.interop.register = true;

  networking.hostName = "wsl";

  services.tailscale.enable = true;

  # cody is created by wsl.defaultUser; just set the login shell and grant sudo.
  users.users.cody = {
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };
  programs.fish.enable = true;

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
    gcc
  ];

  # Lets uv's own downloaded Python builds (and other prebuilt, dynamically
  # linked binaries for generic Linux) execute at all -- NixOS has no
  # standard dynamic-linker path by default and blocks them with a
  # "stub-ld" error otherwise. Kept deliberately limited to uv/Python
  # development needs; add more libraries here as specific tools need them.
  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.zlib
      pkgs.stdenv.cc.cc.lib
      pkgs.expat
    ];
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
