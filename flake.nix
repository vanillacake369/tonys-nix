{
  description = "Custom basic linux configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, system-manager, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      pkgsAllowUnfree = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      # Define the home configuration
      homeConfigurations = {
        limjihoon = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
        };
      };

      # Define system manager to cope with linux distro system
      systemConfigs.default = system-manager.lib.makeSystemConfig {
        modules = [
          ./modules
        ];
      };
      
      # Define the Podman package
      packages.podman = import ./podman.nix { inherit pkgs; };

      # Development shell
      devShells.default = pkgsAllowUnfree.mkShell {
        buildInputs = with pkgsAllowUnfree; [
          neovim
          self.packages.${system}.podman
        ];
        shellHook = ''
          echo "Entering the nix devShell"
          echo "Podman path: ${self.packages.${system}.podman}"
          
          ls -al ${self.packages.${system}.podman}/opt/cni
          mkdir --parent /opt/cni/bin/
          exec ${self.packages.${system}.podman}/fsh-podman-rootless-env
        '';
      };
    };
}
