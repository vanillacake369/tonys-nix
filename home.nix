{ lib, pkgs, config, ... }: 
{
  # Enable Home Manager
  programs.home-manager.enable = true;
 
  # Set env automatically
  targets.genericLinux.enable = true;

  # Import dotfiles
  home.file = {
    ".config/nix".source = ./dotfiles/nix;
    ".config/nvim".source = ./dotfiles/nvim;
  };

  # Import all modularized configurations
  imports = [
    # Infra
    ./modules/infra.nix
    
    # Dev
    ./modules/language.nix

    # Shell
    ./modules/apps.nix
    ./modules/nvim.nix
    ./modules/zsh.nix
    ./modules/shell.nix
  ];
}
