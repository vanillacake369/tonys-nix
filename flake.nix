{
    description = "Multi‑platform flake (NixOS, WSL, Linux, MacOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      system-manager,
      nix-darwin,
      ...
    }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      # Define overlays for package customizations
      overlays = [
        (final: prev: {
          google-chrome = prev.google-chrome.override {
            commandLineArgs = "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3";
          };
          slack = final.symlinkJoin {
            name = "slack";
            paths = [ prev.slack ];
            buildInputs = [ final.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/slack \
                --add-flags "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3"
            '';
          };
        })
      ];
      
      # Shared home-manager modules
      homeManagerModules = [
        ./home.nix
        ./limjihoon-user.nix
      ];
      
      # Import builders from lib directory
      builders = import ./lib/builders.nix { inherit nixpkgs home-manager homeManagerModules overlays; };
      
      # Support multiple hostname configurations
      hostnames = [ "HAMA" "nixos" ];
    in
    {
      # Define nixos configuration for multiple hostnames
      nixosConfigurations = lib.genAttrs hostnames (hostname: 
        let systemConfig = builders.mkSystem "x86_64-linux";
        in nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = systemConfig.pkgs;
          modules = [
            ./configuration.nix
          ];
        });

      # Define macos configuration for multiple hostnames and architectures
      darwinConfigurations = 
        let 
          darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
          mkDarwinConfig = hostname: system:
            let systemConfig = builders.mkSystem system;
            in nix-darwin.lib.darwinSystem {
              inherit system;
              pkgs = systemConfig.pkgs;
              modules = [
                ./configuration.nix
              ];
            };
        in
        lib.listToAttrs (
          lib.flatten (
            map (hostname: 
              map (system: {
                name = "${hostname}-${system}";
                value = mkDarwinConfig hostname system;
              }) darwinSystems
            ) hostnames
          )
        );
      
      # Home-manager configurations - separate WSL and non-WSL configs
      homeConfigurations = lib.listToAttrs (
        lib.flatten (
          map (system: [
            # Non-WSL configuration
            {
              name = "hm-${system}";
              value = builders.mkHomeConfig { 
                inherit system; 
                isWsl = false;
              };
            }
            # WSL configuration
            {
              name = "hm-wsl-${system}";
              value = builders.mkHomeConfig { 
                inherit system; 
                isWsl = true;
              };
            }
          ]) supportedSystems
        )
      );
      
      # Define system manager to cope with linux distro system
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          ./modules
        ];
      };
    };
}
