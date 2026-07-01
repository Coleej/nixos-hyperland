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
    hypr-binds = {
      url = "github:hyprland-community/hypr-binds";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    hyprland,
    hypr-binds,
    sops-nix,
    nixos-wsl,
    ...
  }: let
    hosts = {
      default = {
        user = {
          name = "cody";
          group = "users";
          home = "/home/cody";
          description = "Cody";
          extraGroups = [];
        };
      };
      amd-workstation = {
        user = {
          name = "cody";
          group = "users";
          home = "/home/cody";
          description = "Cody";
          extraGroups = [];
        };
      };
      wsl = {
        wsl = true;
        homeModule = ./home-wsl.nix;
        user = {
          name = "cody";
          group = "users";
          home = "/home/cody";
          description = "Cody";
          extraGroups = [];
        };
      };
    };

    makeHostConfig = hostName: hostData: let
      isWsl = hostData.wsl or false;
    in
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [
            ./hosts/${hostName}/system.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
          ]
          ++ nixpkgs.lib.optional isWsl nixos-wsl.nixosModules.default
          ++ [
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${hostData.user.name} = {
                imports =
                  [
                    (hostData.homeModule or ./home.nix)
                    sops-nix.homeManagerModules.default
                  ]
                  ++ nixpkgs.lib.optional (!isWsl) hypr-binds.homeManagerModules.x86_64-linux.default;
                _module.args = {
                  inherit self;
                  hostName = hostName;
                  hostUser = hostData.user;
                };
              };
            }
            {_module.args = {inherit hyprland self;};}
          ];
        specialArgs = {
          inherit hyprland self;
          hostUser = hostData.user;
        };
      };
  in {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosModules = {
      hyperland = import ./modules/shared;
    };

    nixosConfigurations = nixpkgs.lib.mapAttrs makeHostConfig hosts;
  };
}
