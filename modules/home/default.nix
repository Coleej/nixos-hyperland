{ ... }:
{
  imports = [
    ./packages.nix
    ./shell.nix
    ./desktop.nix
    ./services.nix
    ./secrets.nix
    ./git.nix
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
