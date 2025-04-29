{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Import dotfiles
  home.file = {
    ".config/nix".source = ./dotfiles/nix;
  };

  # Import all modularized configurations
  imports = [
    # Infra
    ./modules/pkgs/k8s.nix
    
    # Langs
    ./modules/pkgs/language.nix

    # Shell
    ./modules/pkgs/apps.nix
    ./modules/pkgs/nvim.nix
    ./modules/pkgs/zsh.nix
    ./modules/pkgs/shell.nix
  ];
}
