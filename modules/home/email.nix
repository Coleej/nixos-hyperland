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
}
