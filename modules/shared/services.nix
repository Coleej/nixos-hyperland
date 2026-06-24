{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hyperland.services;
in {
  options.hyperland.services = {
    enable = lib.mkEnableOption "Shared baseline services (pipewire, flatpak, polkit, sudo)";
    openssh.enable = lib.mkEnableOption "OpenSSH server";
    tlp.enable = lib.mkEnableOption "TLP power management (recommended for laptops)";
  };

  config = lib.mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    services.flatpak.enable = true;
    security.polkit.enable = true;
    security.rtkit.enable = true;
    security.sudo.wheelNeedsPassword = false;

    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.blueman.enable = true;
    services.avahi = {
      enable = true;
      nssmdns4 = true;
    };
    services.gnome.gnome-keyring.enable = true;

    # Auto-unlock gnome-keyring at login
    security.pam.services.gdm.enableGnomeKeyring = true;
    security.pam.services.login.enableGnomeKeyring = true;
    security.pam.services.hyprlock.enableGnomeKeyring = true;

    services.openssh.enable = lib.mkIf cfg.openssh.enable true;

    services.tlp = lib.mkIf cfg.tlp.enable {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    # Evolution mail client
    programs.evolution.enable = true;
  };
}
