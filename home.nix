{
  config,
  pkgs,
  lib,
  self,
  ...
}: let
  hyprConfigFiles = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (f: f.hasExt "conf") ./configs;
  };
in {
  home.username = "cody";
  home.homeDirectory = "/home/cody";
  home.stateVersion = "25.11";

  home.file = {
    ".config/hypr/hyprland-base.conf" = {
      source = hyprConfigFiles + /configs/hyprland-base.conf;
      force = true;
    };
    ".config/hypr/hyprland.conf" = {
      source = hyprConfigFiles + /configs/hyprland-default.conf;
      force = true;
    };
    ".config/hypr/hyprland-monitors.conf" = {
      source = hyprConfigFiles + /configs/hyprland-monitors.conf;
      force = true;
    };
  };

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
    fastfetch
    direnv
    gh
    uv
    taskwarrior-tui
    newsboat
    git-lfs
    ranger
    xclip
    firefox
    tree-sitter
    telegram-desktop

    # LSP servers and formatters (managed by OS instead of Mason)
    pyright
    lua-language-server
    ruff
    stylua
  ];

  programs.home-manager.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -U fish_greeting ""

      # Cargo env
      if test -f "$HOME/.cargo/env"
        . "$HOME/.cargo/env"
      end

      # Nix profile
      if test -f "$HOME/.nix-profile/etc/profile.d/nix.sh"
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      end

      # Direnv
      set -gx DIRENV_LOG_FORMAT ""
      direnv hook fish | source

      # Activate uv virtual environment
      function activate
        set -l venv_name $argv[1]
        set -l venv_path "$HOME/.config/uv/venvs/$venv_name"
        if test -z "$venv_name"
          echo "Usage: activate <environment_name>"
          return 1
        end
        if not test -d "$venv_path"
          echo "Error: Virtual environment '$venv_name' does not exist at $venv_path."
          return 1
        end
        source "$venv_path/bin/activate.fish"
        echo "'$venv_name' virtual environment activated."
      end
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      command_timeout = 10000;
      scan_timeout = 5000;
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

  programs.alacritty = {
    enable = true;
  };

  home.file.".config/alacritty/alacritty.toml".text = ''
    [font]
    size = 12

    [font.normal]
    family = "FiraCode Nerd Font"
  '';


  nixpkgs.config.allowUnfree = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XDG_CONFIG_HOME = "\${HOME}/.config";
  };

  home.sessionPath = ["\${HOME}/.local/bin" "\${HOME}/.cargo/bin"];
}
