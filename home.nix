{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    ./modules/pkgs/just-pkgs.nix
    ./modules/pkgs/kubernetes-pkgs.nix
    ./modules/pkgs/jenkins-pkgs.nix
    ./modules/pkgs/zsh-pkgs.nix
    ./modules/pkgs/nvim-pkgs.nix
    ./modules/user.nix
  ];

}
