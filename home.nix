{ lib, pkgs, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/programs.nix
    ./modules/kubernetes.nix
    ./modules/user.nix
  ];
}
