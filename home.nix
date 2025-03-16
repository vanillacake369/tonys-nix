{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import all modularized configurations
  imports = [
    ./modules/pkgs/basic-pkgs.nix
    ./modules/pkgs/just-pkgs.nix
    ./modules/pkgs/podman-pkgs.nix
    ./modules/pkgs/kubernetes-pkgs.nix
    ./modules/pkgs/jenkins-pkgs.nix
    ./modules/configs/zsh-config.nix
    ./modules/user.nix
  ];

}
