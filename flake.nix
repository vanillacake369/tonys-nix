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
      
      mkSystem = system:
        let
          # Overlays on pkgs
          pkgs = import nixpkgs {
            inherit system;
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
            config.allowUnfree = true;
          };
          # Pass boolean flag of linux or darwin
          isLinux = pkgs.stdenv.isLinux;
          isDarwin = pkgs.stdenv.isDarwin;
        in {
          inherit pkgs isLinux isDarwin;
        };
      
      # Support multiple hostname configurations
      # Add hostnames here to support justfile's {{HOSTNAME}} variable
      hostnames = [ "HAMA" "nixos" ];
    in
    {
      # Define nixos configuration for multiple hostnames
      nixosConfigurations = lib.genAttrs hostnames (hostname: 
        let systemConfig = mkSystem "x86_64-linux";
        in nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = systemConfig.pkgs;
          modules = [
            ./configuration.nix
          ];
        });
      
      # Define the home-manager configuration for each supported system
      homeConfigurations = forAllSystems (system:
        let systemConfig = mkSystem system;
        in {
          # WSL Home Manager configuration
          hm-wsl = home-manager.lib.homeManagerConfiguration {
            pkgs = systemConfig.pkgs;
            modules = [
              ./home.nix
              ./limjihoon-user.nix
            ];
            extraSpecialArgs = {
              inherit (systemConfig) isLinux isDarwin;
              isWsl = true;
            };
          };
          # NixOS Home Manager configuration
          hm-nixos = home-manager.lib.homeManagerConfiguration {
            pkgs = systemConfig.pkgs;
            modules = [
              ./home.nix
              ./limjihoon-user.nix
            ];
            extraSpecialArgs = {
              inherit (systemConfig) isLinux isDarwin;
              isWsl = false;
            };
          };
        }) // {
          # Default configurations for current system (fallback)
          hm-wsl = let systemConfig = mkSystem "x86_64-linux"; in
            home-manager.lib.homeManagerConfiguration {
              pkgs = systemConfig.pkgs;
              modules = [
                ./home.nix
                ./limjihoon-user.nix
              ];
              extraSpecialArgs = {
                inherit (systemConfig) isLinux isDarwin;
                isWsl = true;
              };
            };
          hm-nixos = let systemConfig = mkSystem "x86_64-linux"; in
            home-manager.lib.homeManagerConfiguration {
              pkgs = systemConfig.pkgs;
              modules = [
                ./home.nix
                ./limjihoon-user.nix
              ];
              extraSpecialArgs = {
                inherit (systemConfig) isLinux isDarwin;
                isWsl = false;
              };
            };
        };
      
      # Define system manager to cope with linux distro system
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          ./modules
        ];
      };
    };
}
