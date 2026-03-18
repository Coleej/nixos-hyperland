{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.hyperland.shell;
  user = config.hyperland.user;
  userHome = user.home;
  userName = user.name;
in
{
  options.hyperland.shell = {
    enable = lib.mkEnableOption "Fish + Oh My Posh + Atuin shell setup";
    atuin.enable = lib.mkEnableOption "Enable Atuin shell history integration";
    kittyConfig.enable = lib.mkEnableOption "Write a shared kitty.conf to the user's config";
    defaultTerminal = lib.mkOption {
      type = lib.types.str;
      default = "alacritty";
      description = "Default terminal emulator";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish.enable = true;
    environment.systemPackages =
      [ pkgs.oh-my-posh ]
      ++ lib.optionals cfg.atuin.enable [ pkgs.atuin ];

    systemd.user.services.hyperland-shell-setup = {
      description = "Hyperland: setup shell config in user home";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyperland-shell-setup" ''
          set -euo pipefail
          echo "[hyperland][shell] setting up shell config"

          mkdir -p ${userHome}/.config/fish/conf.d
          mkdir -p ${userHome}/.config/oh-my-posh

          cat > ${userHome}/.config/fish/conf.d/grc.fish << 'EOF'
          if not set -q GRC_DISABLE; and command -q grc
            function __grc_wrap
              grc $argv
            end
            set -l __grc_targets diff dig ip last mount netstat ping ping6 ps traceroute traceroute6
            for t in $__grc_targets
              alias $t "__grc_wrap $t"
            end
          end
EOF

          cat > ${userHome}/.config/fish/conf.d/oh-my-posh.fish << 'EOF'
          set -gx OMP_CONFIG "$HOME/.config/oh-my-posh/config.json"
          if set -q XDG_CACHE_HOME
            set -gx POSH_CACHE_DIR "$XDG_CACHE_HOME/oh-my-posh"
          else
            set -gx POSH_CACHE_DIR "$HOME/.cache/oh-my-posh"
          end
          if command -q oh-my-posh
            if test -r "$OMP_CONFIG"
              oh-my-posh init fish --config "$OMP_CONFIG" | source
            else
              oh-my-posh init fish | source
            end
          end
EOF

          cat > ${userHome}/.config/fish/conf.d/local-bin.fish << 'EOF'
          if test -d "$HOME/.local/bin"
            fish_add_path "$HOME/.local/bin"
          end
EOF

          ${lib.optionalString (cfg.atuin.enable or false) ''
            cat > ${userHome}/.config/fish/conf.d/atuin.fish << 'ATUINEOF'
            if command -q atuin
              set -g ATUIN_SESSION (atuin uuid)
              atuin init fish | source
            end
ATUINEOF
          ''}

          if [ ! -f ${userHome}/.config/oh-my-posh/config.json ]; then
            cat > ${userHome}/.config/oh-my-posh/config.json << 'OMP_EOF'
            {
              "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
              "version": 3,
              "final_space": true,
              "blocks": [
                {
                  "type": "prompt",
                  "alignment": "left",
                  "segments": [
                    { "type": "root", "style": "powerline", "background": "#ffe9aa", "foreground": "#100e23", "powerline_symbol": "\ue0b0", "template": " \uf0e7 " },
                    { "type": "session", "style": "powerline", "background": "#ffffff", "foreground": "#100e23", "powerline_symbol": "\ue0b0", "template": " {{ .UserName }}@{{ .HostName }} " },
                    { "type": "path", "style": "powerline", "background": "#91ddff", "foreground": "#100e23", "powerline_symbol": "\ue0b0", "properties": { "style": "agnoster", "max_depth": 2, "max_width": 50 }, "template": " {{ .Path }} " },
                    { "type": "git", "style": "powerline", "background": "#95ffa4", "foreground": "#193549", "powerline_symbol": "\ue0b0", "properties": { "fetch_status": true }, "template": " {{ .UpstreamIcon }}{{ .HEAD }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }} " },
                    { "type": "python", "style": "powerline", "background": "#FFDE57", "foreground": "#111111", "powerline_symbol": "\ue0b0", "properties": { "fetch_virtual_env": true, "display_version": true }, "template": " \ue235 {{ if .Venv }}{{ .Venv }} {{ end }}{{ .Full }} " },
                    { "type": "exit", "style": "powerline", "background": "#f7768e", "foreground": "#ffffff", "powerline_symbol": "\ue0b0", "properties": { "display_exit_code": true }, "template": " {{ if gt .Code 0 }}\uf071 {{ .Code }}{{ end }} " }
                  ]
                },
                {
                  "type": "rprompt",
                  "segments": [
                    { "type": "time", "style": "plain", "foreground": "#9aa5ce", "template": " {{ .CurrentDate | date .Format }} " }
                  ]
                }
              ]
            }
OMP_EOF
          fi

          echo "[hyperland][shell] shell setup complete"
        '';
      };
    };

    systemd.user.services.hyperland-kitty-setup = lib.mkIf (cfg.kittyConfig.enable or false) {
      description = "Hyperland: write kitty.conf in user home";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hyperland-kitty-setup" ''
          set -euo pipefail
          mkdir -p ${userHome}/.config/kitty
          cat > ${userHome}/.config/kitty/kitty.conf << 'EOF'
          font_family FiraCode Nerd Font
          font_size 12
          background #1a1b26
          foreground #c0caf5
          shell fish
          enable_audio_bell no
EOF
        '';
      };
    };
  };
}
