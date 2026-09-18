{...}: {
  # Desktop-only: installs the hermes CLI and the Hermes Desktop Electron
  # app. The agent itself runs on a remote server, so no local services or
  # gateway are enabled — the desktop app is configured to connect to it via
  # the GUI's remote mode.
  programs.hermes-agent = {
    enable = true;
    desktop.enable = true;
  };
}
