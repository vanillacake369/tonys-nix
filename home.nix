{
  lib,
  isLinux,
  isDarwin,
  isNixOs,
  ...
}: {
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Set env automatically (Linux only)
  targets.genericLinux.enable = isLinux;

  # Import dotfiles
  home.file =
    {
      ".config/nix".source = ./dotfiles/nix;
      ".config/nixpkgs".source = ./dotfiles/nixpkgs;
      ".config/nvim".source = ./dotfiles/lazyvim;
      ".screenrc".source = ./dotfiles/screen/.screenrc;

      # Claude configuration - only manage static files
      ".claude/commands".source = ./dotfiles/claude/commands;
      ".claude/settings.json".source = ./dotfiles/claude/settings.json;
      ".claude/CLAUDE.md".source = ./dotfiles/claude/CLAUDE.md;
      ".claude/agents".source = ./dotfiles/claude/agents;

      # Zellij configuration
      ".config/zellij/config.kdl".source =
        if isDarwin
        then ./dotfiles/zellij/config.kdl.darwin
        else ./dotfiles/zellij/config.kdl.linux;

      # Hyprland configuration (Linux only)
      ".config/hypr/hyprland.conf".source = ./dotfiles/hypr/hyprland.conf;
    }
    // lib.optionalAttrs isDarwin {
      # Karabiner json
      ".config/karabiner/karabiner.json".source = ./dotfiles/karabiner/karabiner.json;

      # Yabai & Skhd (Mac only)
      ".config/yabai/yabairc".source = ./dotfiles/yabai/yabairc;
      ".skhdrc".source = ./dotfiles/skhd/skhdrc;
    };

  # Packages
  imports =
    [
      ./modules/apps.nix
      ./modules/language.nix
      ./modules/shell-core.nix
      ./modules/shell-infra.nix
      ./modules/shell-utils.nix
      ./modules/shell-network.nix
      ./modules/shell-monitor.nix
      ./modules/shell-services.nix
    ]
    ++ lib.optionals isNixOs [./modules/settings-hyprland.nix]
    ++ lib.optionals (isLinux && !isNixOs) [./modules/settings-wsl.nix]
    ++ lib.optionals isDarwin [./modules/settings-mac.nix];
}
