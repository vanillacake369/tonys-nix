{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;
 
  # Set env automatically
  targets.genericLinux.enable = true;

  # Import dotfiles
  home.file = {
    ".config/nix".source = ./dotfiles/nix;
  };

  # Import all modularized configurations
  imports = [
    # Infra
    ./modules/k8s.nix
    
    # Langs
    ./modules/language.nix

    # Shell
    ./modules/apps.nix
    ./modules/nvim.nix
    ./modules/zsh.nix
    ./modules/shell.nix
  ];
}
