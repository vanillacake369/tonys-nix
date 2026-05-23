{
  description = "Multi-platform flake (NixOS, WSL, Linux, MacOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nixos-generators,
    llm-agents,
    ...
  }: let
    lib = nixpkgs.lib;
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = lib.genAttrs supportedSystems;

    # Auto-collect overlays from modules (*.overlay.nix convention)
    collectOverlays = import ./lib/discover-overlays.nix {inherit lib;};
    overlays = collectOverlays ./modules ++ [llm-agents.overlays.default];

    # Auto-discover user profiles
    discoverModules = import ./lib/discover-modules.nix {inherit lib;};
    userProfiles = discoverModules ./user;

    # Builders
    builders = import ./lib/mk-home-config.nix {
      inherit nixpkgs home-manager overlays;
      homeManagerModules = [./home.nix];
    };
    mkImages = import ./lib/mk-images.nix {
      inherit lib nixos-generators;
      configModules = [./configuration.nix];
    };

    hostnames = ["tony"];
  in {
    nixosConfigurations = lib.genAttrs hostnames (_:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        pkgs = (builders.mkSystem "x86_64-linux").pkgs;
        modules = [./configuration.nix];
      });

    homeConfigurations = lib.listToAttrs (lib.flatten (
      map (system: [
        {
          name = "hm-${system}";
          value = builders.mkHomeConfig {
            inherit system;
            userProfile = userProfiles.limjihoon;
          };
        }
        {
          name = "hm-wsl-${system}";
          value = builders.mkHomeConfig {
            inherit system;
            userProfile = userProfiles.limjihoon;
            isWsl = true;
          };
        }
        {
          name = "hm-nixos-${system}";
          value = builders.mkHomeConfig {
            inherit system;
            userProfile = userProfiles.limjihoon;
            isNixOs = true;
          };
        }
      ])
      supportedSystems
    ));

    packages = forAllSystems mkImages;

    tests = import ./tests/guard-tests.nix {inherit lib;};
  };
}
