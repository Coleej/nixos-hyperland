{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "cody";
  home.homeDirectory = "/home/cody";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release introduces backwards incompatible changes. You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    pkgs.libgcc
    pkgs.gcc
    pkgs.htop
    pkgs.taskwarrior3
    pkgs.neovim
    pkgs.xonsh
    pkgs.nmap
    pkgs.fish
    pkgs.yadm
    pkgs.git
    pkgs.devenv
    pkgs.ripgrep
    pkgs.wl-clipboard
    pkgs.xclip
    pkgs.lemonade
    pkgs.alacritty
    pkgs.pavucontrol
    pkgs.broot
    pkgs.tre-command
    pkgs.signal-desktop-bin
    pkgs.telegram-desktop
    pkgs.fd
    pkgs.yarn
    pkgs.nodejs
    pkgs.gnumake
    pkgs.lua5_1
    pkgs.luarocks
    pkgs.direnv
    pkgs.neofetch
    pkgs.smartmontools
    pkgs.nerd-fonts.hack
    pkgs.wget
    pkgs.vale
    pkgs.tree-sitter
    pkgs.ghostty
    pkgs.newsboat
    pkgs.ffmpeg
    pkgs.uv
    pkgs.poppler-utils
    pkgs.git-lfs
    pkgs.gdal
    pkgs.zip
    pkgs.unzip
    pkgs.ranger
    pkgs.duf
    pkgs.markdownlint-cli
    pkgs.nchat
    pkgs.gh
    pkgs.whosthere
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };
  
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/cody/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Shell
  programs.bash = {
    enable = true;

    bashrcExtra = ''
      # Old bash file
      . ~/.bashrc.backup

      # Completions for aichat
      . ~/.config/aichat/integrations/aichat.bash

      # Shell integration for aichat
      . ~/.config/aichat/integrations/integration.bash

      # XDG
      export XDG_CONFIG_HOME=~/.config

      # set anthropic key (loaded from file to avoid committing secrets)
      if [ -f "$HOME/.config/secrets/avante-anthropic-api-key" ]; then
        export AVANTE_ANTHROPIC_API_KEY=$(cat "$HOME/.config/secrets/avante-anthropic-api-key")
      fi

      if [ -f "$HOME/.config/secrets/avante-openrouter-api-key" ]; then
        export AVANTE_OPENROUTER_API_KEY=$(cat "$HOME/.config/secrets/avante-openrouter-api-key")
      fi

      # start fish
      if [[ $SHELL != "$(which fish)" && -z "$BASH_EXECUTION_STRING" ]]; then
        exec fish
      fi
    '';
  };

  # Shell prompt - Adds some fancy functions to shell prompt.
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

  # fish shell
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -U fish_greeting ""
    '';
  };

  # fzf
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # configure nix packages
  nixpkgs.config = {
    allowUnfree = true;
  };

}
