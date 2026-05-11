{
  lib,
  pkgs,
  isLinux,
  isDarwin,
  isWsl,
  isNixOs,
  nvim-config,
  ...
}: {
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Set env automatically (Linux only)
  targets.genericLinux.enable = isLinux;

  # Import dotfiles (agent configs moved to modules/agents.nix)
  home.file =
    {
      ".config/nix".source = ./dotfiles/nix;
      ".config/nixpkgs".source = ./dotfiles/nixpkgs;
      ".screenrc".source = ./dotfiles/screen/.screenrc;
      # ".config/nvim".source = nvim-config;

      # Zellij configuration
      ".config/zellij/config.kdl".source =
        if isDarwin
        then ./dotfiles/zellij/config.kdl.darwin
        else ./dotfiles/zellij/config.kdl.linux;

      # Hyprland configuration (Linux only)
      ".config/hypr/hyprland.conf".source = ./dotfiles/hypr/hyprland.conf;
    }
    // lib.optionalAttrs isDarwin {
      # Keymapper :: karabiner
      ".config/karabiner/karabiner.json" = {
        source = ./dotfiles/karabiner/karabiner.json;
        force = true;
      };

      # Window manager :: Aerospace
      ".config/aerospace".source = ./dotfiles/aerospace;
    };

  # Packages
  imports =
    [
      ./modules/agents
      ./modules/apps.nix
      ./modules/language.nix
      ./modules/shell-core.nix
      ./modules/shell-infra.nix
      ./modules/shell-utils.nix
      ./modules/shell-network.nix
      ./modules/shell-monitor.nix
    ]
    ++ lib.optionals isNixOs [./modules/settings-hyprland.nix]
    ++ lib.optionals (isLinux && !isNixOs) [./modules/settings-wsl.nix]
    ++ lib.optionals isDarwin [./modules/settings-mac.nix];
}
