{...}: {
  # Minimal headless Home Manager profile for the WSL host.
  # Terminal-only: reuses shell + git, adds a curated CLI toolchain and
  # taskwarrior sync. No desktop.nix, email, or GUI packages.
  imports = [
    ./packages-wsl.nix
    ./shell.nix
    ./git.nix
    ./secrets-wsl.nix
    ./taskwarrior.nix
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "\${HOME}/.config";
  };

  home.sessionPath = [
    "\${HOME}/.local/bin"
    "\${HOME}/.cargo/bin"
  ];
}
