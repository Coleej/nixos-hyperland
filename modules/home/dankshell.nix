{
  osConfig ? {},
  pkgs,
  lib,
  ...
}: let
  # Driven by the NixOS-side switch (hyprspace.dankshell.enable). osConfig is
  # absent for standalone HM, where this cleanly defaults to disabled. The
  # dms flake module (imported in flake.nix for non-WSL hosts) provides the
  # programs.dank-material-shell options.
  enabled = osConfig.hyprspace.dankshell.enable or false;
in {
  config = lib.mkIf enabled {
    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      enableSystemMonitoring = true;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;
      enableCalendarEvents = false;
      # settings/session intentionally unmanaged — tweak in the DMS GUI,
      # codify here later if desired.
    };

    # System monitoring widget backend (dgop)
    home.packages = [pkgs.dgop];
  };
}
