{
  config,
  lib,
  ...
}: {
  # Minimal sops-nix wiring for the headless WSL host.
  # Only the terminal-relevant secrets are declared here (consumed by taskwarrior.nix
  # and the writeAnthropicApiKey activation hook below).
  # The age private key must exist at the path below before the first `nixos-rebuild switch`.
  sops = {
    age.keyFile = "/home/cody/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      taskchampion_secret = {};
      anthropic_api_key_wsl = {};
    };
  };

  home.activation.writeAnthropicApiKey = lib.hm.dag.entryAfter ["linkGeneration"] ''
    secret_path="${config.sops.secrets.anthropic_api_key_wsl.path}"
    key_path="${config.home.homeDirectory}/.config/anthropic/api_key"
    if [ -f "$secret_path" ]; then
      mkdir -p "${config.home.homeDirectory}/.config/anthropic"
      cp "$secret_path" "$key_path"
      chmod 600 "$key_path"
    fi
  '';
}
