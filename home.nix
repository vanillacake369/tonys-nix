{ lib, pkgs, config, isLinux, isDarwin, isWsl, ... }:

{
  # Enable Home Manager
  programs.home-manager.enable = true;
 
  # Set env automatically
  targets.genericLinux.enable = true;

  # Import dotfiles
  home.file = {
    ".config/nix".source = ./dotfiles/nix;
    ".config/nixpkgs".source = ./dotfiles/nixpkgs;
    ".config/nvim".source = ./dotfiles/nvim;
    ".screenrc".source = ./dotfiles/screen/.screenrc;
  };

  # Core pkgs
  # Pass isLinux, isDarwin, isWsl
  imports = [
    ./modules/infra.nix
    ./modules/language.nix
    ./modules/nvim.nix
    ./modules/zsh.nix
    ./modules/shell.nix
  ]
  # NixOs / Darwin pkgs
  ++ (lib.optionals (!isWsl && isLinux || isDarwin) [
    ./modules/apps.nix
  ])
  # WSL pkgs
  ++ (lib.optionals isWsl [
  ]);
}
