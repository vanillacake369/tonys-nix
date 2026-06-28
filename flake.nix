{
  description = "Multi-platform flake (NixOS, WSL, Linux, MacOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pin neovim 0.11.6 — last nixpkgs commit before 0.12 bump.
    # 0.12.x breaks treesitter plugins; this input provides neovim-unwrapped only.
    nixpkgs-neovim.url = "github:nixos/nixpkgs/d86da6ff1a3db2d1e667684c6f34c21896767b3e";
  };

  outputs = {
    nixpkgs,
    nixpkgs-neovim,
    home-manager,
    llm-agents,
    ...
  }: let
    inherit (nixpkgs) lib;
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    homeActivationCheckSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = lib.genAttrs supportedSystems;

    # Auto-collect overlays from modules (*.overlay.nix convention)
    overlays =
      (import ./lib/collect-overlays.nix {inherit lib;}) ./modules
      ++ [
        llm-agents.overlays.default
        # Pin neovim-unwrapped from older nixpkgs (0.11.6)
        (_final: _prev: {
          neovim-unwrapped = nixpkgs-neovim.legacyPackages.${_prev.stdenv.hostPlatform.system}.neovim-unwrapped;
        })
      ];

    # Auto-discover user profiles (one attr per user/<name>.nix)
    userProfiles = lib.pipe (builtins.readDir ./user) [
      (lib.filterAttrs (_: type: type == "regular"))
      builtins.attrNames
      (builtins.filter (lib.hasSuffix ".nix"))
      (map (name: {
        name = lib.removeSuffix ".nix" name;
        value = import (./user + "/${name}");
      }))
      builtins.listToAttrs
    ];

    # Builders
    builders = import ./lib/mk-home-config.nix {
      inherit nixpkgs home-manager overlays;
      homeManagerModules = [./home.nix];
    };
    mkImages = import ./lib/mk-images.nix {
      inherit lib nixpkgs;
      configModules = [./configuration.nix];
    };

    hostnames = ["tony"];
    collectTests = (import ./lib/collect-tests.nix {inherit lib;}) ./tests;
  in rec {
    nixosConfigurations = lib.genAttrs hostnames (_:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        inherit ((builders.mkSystem "x86_64-linux")) pkgs;
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

    checks = forAllSystems (system: let
      pkgs = (builders.mkSystem system).pkgs;
      homeConfig = homeConfigurations."hm-${system}";
      collectChecks = (import ./lib/collect-checks.nix {inherit lib;}) ./tests;
      tests = collectTests {inherit lib;};
    in
      collectChecks {
        inherit pkgs homeConfig tests;
      }
      // lib.optionalAttrs (builtins.elem system homeActivationCheckSystems) {
        home-activation = homeConfig.activationPackage;
      });
  };
}
