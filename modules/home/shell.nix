{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -U fish_greeting ""

      if test -f "$HOME/.cargo/env"
        . "$HOME/.cargo/env"
      end

      if test -f "$HOME/.nix-profile/etc/profile.d/nix.sh"
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
      end

      set -gx DIRENV_LOG_FORMAT ""
      direnv hook fish | source

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
}
