{
  lib,
  pkgs,
  config,
  isLinux,
  isDarwin,
  isWsl,
  ...
}: {
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Set env automatically (Linux only)
  targets.genericLinux.enable = isLinux;

  # Import dotfiles
  home.file = {
    ".config/nix".source = ./dotfiles/nix;
    ".config/nixpkgs".source = ./dotfiles/nixpkgs;
    ".config/nvim".source = ./dotfiles/lazyvim;
    ".screenrc".source = ./dotfiles/screen/.screenrc;

    # Claude configuration - only manage static files
    ".claude/commands".source = ./dotfiles/claude/commands;

    # Zellij configuration - platform-specific
    ".config/zellij/config.kdl".source = 
      if isDarwin then ./dotfiles/zellij/config.kdl.darwin
      else ./dotfiles/zellij/config.kdl.linux;
  };

  # Core pkgs
  # Pass isLinux, isDarwin, isWsl
  imports =
    [
      ./modules/infra.nix
      ./modules/language.nix
      ./modules/nvim.nix
      ./modules/zsh.nix
      ./modules/shell.nix
      ./modules/apps.nix
    ]
    # NixOs / Darwin pkgs
    ++ (lib.optionals (!isWsl && isLinux || isDarwin) [
      ])
    # WSL pkgs
    ++ (lib.optionals isWsl [
      ]);
}
