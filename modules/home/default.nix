{...}: {
  imports = [
    ./packages.nix
    ./shell.nix
    ./desktop.nix
    ./dankshell.nix
    ./services.nix
    ./secrets.nix
    ./git.nix
    ./email.nix
    ./hermes.nix
    ./qmd.nix
    ./qmd-mcp.nix
    ./qmd-reindex.nix
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    COLORTERM = "truecolor";
  };

  home.sessionPath = [
    "\${HOME}/.local/bin"
    "\${HOME}/.cargo/bin"
  ];
}
