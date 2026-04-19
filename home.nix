{
  config,
  pkgs,
  lib,
  self,
  ...
}:
let
  configFiles = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (
      f: f.hasExt "conf" || f.hasExt "json" || f.hasExt "css"
    ) ./configs;
  };
in
{
  home.username = "cody";
  home.homeDirectory = "/home/cody";
  home.stateVersion = "25.11";

  home.file = {
    ".config/hypr/hyprland-base.conf" = {
      source = configFiles + /configs/hyprland-base.conf;
      force = true;
    };
    ".config/hypr/hyprland.conf" = {
      source = configFiles + /configs/hyprland-default.conf;
      force = true;
    };
    ".config/hypr/hyprland-monitors.conf" = {
      source = configFiles + /configs/hyprland-monitors.conf;
      force = true;
    };
    ".config/waybar/config" = {
      source = configFiles + /configs/waybar/config.json;
      force = true;
    };
    ".config/waybar/style.css" = {
      source = configFiles + /configs/waybar/style.css;
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
    newsboat
    git-lfs
    ranger
    xclip
    firefox
    tree-sitter
    telegram-desktop
    whosthere
    dig

    # LSP servers and formatters (managed by OS instead of Mason)
    pyright
    lua-language-server
    ruff
    stylua
    nixd
    nixfmt
    taskwarrior3
  ];

  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
    dataLocation = "${config.xdg.configHome}/task";
    config = {
      rc.taskrc = "${config.xdg.configHome}/task/taskrc";
      sync.server.url = "https://taskchampion.codyjohnson.xyz";
      sync.server.client_id = "9ddb3dd1-e22e-469c-99c0-9a054fecb6bd";
      sync.encryption_secret = "zuNg0hee";
    };
  };

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

  programs.wofi = {
    enable = true;
    settings = {
      allow_markup = true;
      insensitive = true;
    };
    style = ''
      r
      * {
        font-family: "FiraCode Nerd Font";
        font-size: 14px;
        color: #ffffff;
        background-color: #1e1e2e;
        border: none;
        margin: 0;
        padding: 0;
      }

      window {
        margin: 4px;
        border-radius: 6px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.5);
        background-color: #1e1e2e;
      }

      #input {
        padding: 6px 8px;
        margin: 4px;
        border-radius: 4px;
        background-color: #313244;
        border: 2px solid #45475a;
        color: #cdd6f4;
      }

      #input:focus {
        border-color: #89b4fa;
        outline: none;
        box-shadow: 0 0 10px rgba(137, 180, 250, 0.3);
      }

      #outer-box {
        margin: 4px;
        border-radius: 2px;
        background-color: #1e1e2e;
      }

      #scroll {
        margin: 2px;
        background-color: transparent;
      }

      #scroll window {
        background-color: transparent;
      }

      #text {
        padding: 4px 6px;
        margin: 1px 2px;
        border-radius: 2px;
      }

      #entry {
        padding: 6px 8px;
        border-radius: 2px;
      }

      #entry:selected {
        background-color: #89b4fa;
        color: #1e1e2e;
        outline: none;
      }

      #entry:selected #text {
        color: #1e1e2e;  /* Dark gray for contrast on blue bg */
      }

      #entry #text {
        color: #cdd6f4;  /* Light blue-gray for unselected text */
      }
    '';
  };

  programs.hypr-binds = {
    enable = true;
    settings = {
      launcher = {
        app = "wofi";
      };
    };
  };

  home.file.".config/alacritty/alacritty.toml".text = ''
    [font]
    size = 12

    [font.normal]
    family = "FiraCode Nerd Font"
  '';

  home.file.".netrc" = {
    text = ''
      machine nc.codyjohnson.xyz
      login cody
      password 4tCn$u!fQ$tEWR^52SI*
    '';
  };

  home.activation.fixNetrcPermissions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -f "$HOME/.netrc" ]; then
      run chmod 600 "$HOME/.netrc"
    fi
  '';

  systemd.user.services.nextcloud-sync = {
    Unit = {
      Description = "Nextcloud sync";
      After = "network-online.target";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nextcloud-client}/bin/nextcloudcmd -n /home/cody/Nextcloud https://nc.codyjohnson.xyz/";
    };
    Install.WantedBy = [ "multi-user.target" ];
  };

  systemd.user.timers.nextcloud-sync = {
    Unit.Description = "Auto-sync Nextcloud files hourly";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  nixpkgs.config.allowUnfree = true;

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
