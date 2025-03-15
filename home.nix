{ lib, pkgs, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    ./modules/basic-pkgs.nix
    ./modules/kubernetes-pkgs.nix
    ./modules/shell.nix
    ./modules/programs.nix
    ./modules/user.nix
  ];
}
