{ nixpkgs, home-manager, hyprland, outPath }:
let
  flake = import outPath;

  hosts = {
    default = {
      user.name = "cody";
      user.group = "users";
      user.home = "/home/cody";
      user.description = "Cody";
      user.extraGroups = [ ];
    };
  };

  makeHostConfig = hostName: hostData:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          ./${hostName}/system.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${hostData.user.name} = {
              imports = [ ../../home.nix ];
            };
          }
          { _module.args = { inherit hyprland self; hyperlandUser = hostData.user; }; }
        ];
      specialArgs = { inherit hyprland self; hyperlandUser = hostData.user; };
    };
in
nixpkgs.lib.mapAttrs makeHostConfig hosts
