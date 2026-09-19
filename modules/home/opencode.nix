{config, ...}: {
  # opencode AI coding agent — shared by all hosts (desktop + WSL).
  # programs.opencode.enable installs pkgs.opencode via home.packages, so the
  # package is intentionally NOT listed in modules/shared/packages.nix or
  # modules/home/packages-wsl.nix.
  #
  # settings  → ~/.config/opencode/opencode.json  ($schema auto-added)
  # tui       → ~/.config/opencode/tui.json       (theme/keybinds live here on v1.2.15+)
  # Secrets: use opencode's "{file:<sops path>}" substitution in settings values
  # so keys stay out of the Nix store.
  programs.opencode = {
    enable = true;
    settings = {
      provider = {
        hermes = {
          npm = "@ai-sdk/openai-compatible";
          name = "Hermes Agent";
          options = {
            baseURL = "http://100.70.193.47:8642/v1";
            # Key stays out of the Nix store: opencode reads the sops-decrypted
            # file at runtime. Declared in secrets.nix (desktop) / secrets-wsl.nix.
            apiKey = "{file:${config.sops.secrets.hermes_api_server_key.path}}";
          };
          models = {
            hermes-agent = {
              name = "Hermes Agent";
            };
          };
        };
      };
    };
    tui = {
    };
  };
}
