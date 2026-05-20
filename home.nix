{
  lib,
  isLinux,
  isDarwin,
  isNixOs,
  userProfile,
  ...
}: let
  spec = import ./lib/keymaps/spec.nix {inherit lib;};
  rawKeybinds = import ./lib/keymaps/keybinds.nix {inherit userProfile;};
  keybinds = rawKeybinds // {keymaps = spec.validate rawKeybinds.keymaps;};
  toKarabiner = import ./lib/keymaps/to-karabiner.nix {inherit lib keybinds;};
  toAeroSpace = import ./lib/keymaps/to-aerospace.nix {inherit lib keybinds;};
in {
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Set env automatically (Linux only)
  targets.genericLinux.enable = isLinux;

  # Import dotfiles (agent configs moved to modules/agents.nix)
  # Zellij configuration
  # Hyprland configuration (Linux only)
  home.file =
    {
      ".config/nix".source = ./dotfiles/nix;
      ".config/nixpkgs".source = ./dotfiles/nixpkgs;
      ".screenrc".source = ./dotfiles/screen/.screenrc;
      # ".config/nvim".source = nvim-config;
      ".config/zellij/config.kdl".source =
        if isDarwin
        then ./dotfiles/zellij/config.kdl.darwin
        else ./dotfiles/zellij/config.kdl.linux;
      ".config/hypr/hyprland.conf".source = ./dotfiles/hypr/hyprland.conf;
    }
    // lib.optionalAttrs isDarwin {
      ".config/karabiner/karabiner.json" = {
        text = toKarabiner;
        force = true;
      };
      ".config/aerospace/aerospace.toml" = {
        text = toAeroSpace;
        force = true;
      };
      # ".config/karabiner/karabiner.json" = {
      #   source = ./dotfiles/karabiner/karabiner.json;
      #   force = true;
      # };
      # ".config/aerospace".source = ./dotfiles/aerospace;
    };

  # Packages
  imports =
    [
      ./modules/agents
      ./modules/apps.nix
      ./modules/packages/jetbrains.nix
      ./modules/language.nix
      ./modules/shell
      ./modules/shell-infra.nix
      ./modules/shell-utils.nix
      ./modules/shell-network.nix
      ./modules/shell-monitor.nix
    ]
    ++ lib.optionals isNixOs [./modules/settings-hyprland.nix]
    ++ lib.optionals (isLinux && !isNixOs) [./modules/settings-wsl.nix]
    ++ lib.optionals isDarwin [./modules/settings-mac.nix];
}
