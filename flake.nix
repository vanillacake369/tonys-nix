{
  description = "Custom basic linux configuration";

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

  outputs = { self, nixpkgs, home-manager, system-manager, nixos-wsl, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
        inherit system;
        overlays = [(final: prev: {
            google-chrome = prev.google-chrome.override {
              commandLineArgs =
                "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3";
            };
            vscode = prev.vscode.override {
              commandLineArgs =
                 "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3";
            };
            slack = pkgs.symlinkJoin {
              name = "slack";
              paths = [ prev.slack ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/slack \
                  --add-flags "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3"
              '';
            };
        })];
        config.allowUnfree = true;
      };
    in {
      packages.${system}.google-chrome = pkgs.google-chrome;
      # Define nixos configuration
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          inherit pkgs;
          modules = [
            ./configuration.nix
          ];
        };
      };
      # Define the home-manager configuration
      homeConfigurations = {
        hama = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home.nix
            ./limjihoon-user.nix 
          ];
        };     
        limjihoon = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home.nix
            ./limjihoon-user.nix 
          ];
        };        
        nixos = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ 
            ./home.nix
            ./nixos-user.nix 
          ];
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
