{ config, pkgs, lib, hyperlandUser ? null, ... }:

let
  userName = hyperlandUser.name or "cody";
in
{
  home.username = userName;
  home.homeDirectory = "/home/${userName}";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    neovim
    git
    ripgrep
    fd
    fzf
    eza
    bat
    jq
    wget
    curl
    tree
    htop
    btop
    neofetch
    fastfetch
    direnv
    gh
    uv
    taskwarrior-tui
    newsboat
  ];

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -U fish_greeting ""
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 10000;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  nixpkgs.config.allowUnfree = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "\${HOME}/.config";
  };

  home.sessionPath = [ "\${HOME}/.local/bin" ];
}
