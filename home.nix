{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    # Command runner similar to `make`
    ./modules/pkgs/just-pkgs.nix

    # Podman & K8S for rootless container
    ./modules/pkgs/podman-pkgs.nix
    ./modules/pkgs/kubernetes-pkgs.nix
    
    # Shell setup
    ./modules/pkgs/zsh-pkgs.nix
    ./modules/pkgs/nvim-pkgs.nix
    ./modules/pkgs/asciinema-pkgs.nix

    # User metadata
    ./modules/user.nix
  ];

}
