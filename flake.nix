{
  description = "NixOS system configuration with Hyprland";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosModules = {
      hyperland = import ./modules/shared;
    };

    nixosConfigurations =
      let
        hosts = {
          default = {
            user = {
              name = "cody";
              group = "users";
              home = "/home/cody";
              description = "Cody";
              extraGroups = [ ];
            };
          };
        };

        makeHostConfig = hostName: hostData:
          nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules =
              [
                ./hosts/${hostName}/system.nix
                home-manager.nixosModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.users.${hostData.user.name} = {
                    imports = [ ./home.nix ];
                  };
                }
                { _module.args = { inherit hyprland self; hyperlandUser = hostData.user; }; }
              ];
            specialArgs = { inherit hyprland self; hyperlandUser = hostData.user; };
          };
      in
      nixpkgs.lib.mapAttrs makeHostConfig hosts;
  };
}
