{ lib, pkgs, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    # packages
    ./modules/pkgs/basic-pkgs.nix
    ./modules/pkgs/kubernetes-pkgs.nix

    # configs for packages
    ./modules/configs/zsh-config.nix
    ./modules/configs/docker-config.nix

    # basics
    ./modules/shell.nix
    ./modules/user.nix
  ];
}
