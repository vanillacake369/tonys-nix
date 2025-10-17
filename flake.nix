{
  description = "Multi‑platform flake (NixOS, WSL, Linux, MacOS)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-24_11.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-24_11,
    home-manager,
    nix-darwin,
    nixos-generators,
    ...
  }: let
    lib = nixpkgs.lib;
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Define overlays for package customizations
    overlays = [
      (final: prev: {
        google-chrome = prev.google-chrome.override {
          commandLineArgs = "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3";
        };
        slack = final.symlinkJoin {
          name = "slack";
          paths = [prev.slack];
          buildInputs = [final.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/slack \
              --add-flags "--ozone-platform-hint=auto --enable-wayland-ime --enable-features=TouchpadOverscrollHistoryNavigation --wayland-text-input-version=3"
          '';
        };
        # Make nixos-24.11 packages available
        nixos-24_11 = import nixos-24_11 {
          inherit (final) system;
          config = final.config;
        };
      })
    ];

    # Shared home-manager modules
    homeManagerModules = [
      ./home.nix
      ./limjihoon-user.nix
    ];

    # Import builders from lib directory
    builders = import ./lib/builders.nix {inherit nixpkgs home-manager homeManagerModules overlays;};

    # Support multiple hostname configurations
    hostnames = ["HAMA" "nixos"];
  in {
    # Define nixos configuration for multiple hostnames
    # Only create nixosConfigurations if we can access /etc (actual NixOS system)
    nixosConfigurations = lib.optionalAttrs (builtins.pathExists /etc) (
      lib.genAttrs hostnames (hostname: let
        systemConfig = builders.mkSystem "x86_64-linux";
      in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          pkgs = systemConfig.pkgs;
          modules = [
            ./configuration.nix
          ];
        })
    );

    # Define macos configuration for multiple hostnames and architectures
    darwinConfigurations = let
      darwinSystems = ["x86_64-darwin" "aarch64-darwin"];
      mkDarwinConfig = hostname: system: let
        systemConfig = builders.mkSystem system;
      in
        nix-darwin.lib.darwinSystem {
          inherit system;
          pkgs = systemConfig.pkgs;
          modules = [
            ./configuration.nix
          ];
        };
    in
      lib.listToAttrs (
        lib.flatten (
          map (
            hostname:
              map (system: {
                name = "${hostname}-${system}";
                value = mkDarwinConfig hostname system;
              })
              darwinSystems
          )
          hostnames
        )
      );

    # Home-manager configurations - separate WSL, NixOS and standard configs
    homeConfigurations = lib.listToAttrs (
      lib.flatten (
        map (system: [
          # Standard Linux/macOS configuration
          {
            name = "hm-${system}";
            value = builders.mkHomeConfig {
              inherit system;
              isWsl = false;
              isNixOs = false;
            };
          }
          # WSL configuration
          {
            name = "hm-wsl-${system}";
            value = builders.mkHomeConfig {
              inherit system;
              isWsl = true;
              isNixOs = false;
            };
          }
          # NixOS configuration
          {
            name = "hm-nixos-${system}";
            value = builders.mkHomeConfig {
              inherit system;
              isWsl = false;
              isNixOs = true;
            };
          }
        ])
        supportedSystems
      )
    );

    # Image generation using nixos-generators with multiple formats
    packages = forAllSystems (system: let
      # Define available formats with metadata
      formats = {
        iso = { 
          format = "iso"; 
          description = "Bootable ISO image for installation/live boot"; 
        };
        virtualbox = { 
          format = "virtualbox"; 
          description = "VirtualBox OVA image"; 
        };
        vmware = { 
          format = "vmware"; 
          description = "VMware VMDK image"; 
        };
        qcow = { 
          format = "qcow"; 
          description = "QEMU qcow image for KVM/libvirt"; 
        };
      };
      
      # Generate image packages for each format
      mkImage = name: config: nixos-generators.nixosGenerate {
        inherit system;
        modules = [ ./configuration.nix ];
        format = config.format;
      };
    in
      # Only generate Linux images (nixos-generators doesn't support Darwin)
      lib.optionalAttrs (lib.hasSuffix "-linux" system) (
        lib.mapAttrs mkImage formats
      )
    );

  };
}
