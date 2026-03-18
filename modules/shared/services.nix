{ lib, config, pkgs, ... }:
let
  cfg = config.hyperland.services;
in
{
  options.hyperland.services = {
    enable = lib.mkEnableOption "Shared baseline services (pipewire, flatpak, polkit, sudo)";
    openssh.enable = lib.mkEnableOption "OpenSSH server";
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

    services.openssh.enable = lib.mkIf cfg.openssh.enable true;
  };
}
