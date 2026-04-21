{ config, ... }:
{
  sops = {
    age.keyFile = "/home/cody/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets = {
      nextcloud_password = { };
      taskchampion_secret = { };
    };
  };
}
