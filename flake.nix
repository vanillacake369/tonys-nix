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
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      system-manager,
      nixos-wsl,
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
      
      # Clean home-manager configurations without duplication
      # Primary -> WSL, NixOS
      # Secondary(fallback) -> Other OS
      homeConfigurations = {
        hm-wsl = builders.mkHomeConfig { system = "x86_64-linux"; isWsl = true; };
        hm-nixos = builders.mkHomeConfig { system = "x86_64-linux"; isWsl = false; };
      } // (forAllSystems (system: {
        "hm-${system}" = builders.mkHomeConfig { inherit system; isWsl = false; };
      }));
      
      # Define system manager to cope with linux distro system
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          ./modules
        ];
      };
    };
}
