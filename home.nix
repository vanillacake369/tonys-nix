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
    # ** I'm in learning lua by scratch --> https://programmingpercy.tech/blog/learn-how-to-use-neovim-as-ide/ **
    # ".config/nvim".source = ./dotfiles/learn-nvim;
    ".config/zellij".source = ./dotfiles/zellij;
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
