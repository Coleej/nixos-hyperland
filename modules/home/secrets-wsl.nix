{...}: {
  # Minimal sops-nix wiring for the headless WSL host.
  # Only the terminal-relevant secret is declared here (consumed by taskwarrior.nix).
  # The age private key must exist at the path below before the first `nixos-rebuild switch`.
  sops = {
    age.keyFile = "/home/cody/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      taskchampion_secret = {};
    };
  };
}
