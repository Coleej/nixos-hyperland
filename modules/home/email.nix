{
  config,
  pkgs,
  lib,
  ...
}: {
  # Proton Mail Bridge: IMAP/SMTP bridge for Proton Mail accounts
  # - Requires gnome-keyring for credential storage (enabled system-wide)
  # - Initial account login done via protonmail-bridge-gui
  # - Runs as systemd user service, auto-starts after graphical session
  services.protonmail-bridge = {
    enable = true;
    extraPackages = [pkgs.libsecret];
  };

  # Ensure protonmail-bridge starts after graphical session and keyring are ready
  systemd.user.services.protonmail-bridge.Unit.After = lib.mkForce [
    "graphical-session.target"
    "gnome-keyring-daemon.service"
  ];
}
