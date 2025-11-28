{
  lib,
  pkgs,
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
      ".screenrc".source = ./dotfiles/screen/.screenrc;

      # Claude configuration - static files only
      ".claude/commands".source = ./dotfiles/claude/commands;
      ".claude/CLAUDE.md".source = ./dotfiles/claude/CLAUDE.md;
      ".claude/agents".source = ./dotfiles/claude/agents;
      ".claude/skills".source = ./dotfiles/claude/skills;

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

  # Activation script to merge Claude Code configuration
  # This syncs permissions and mcpServers from dotfiles while preserving runtime data
  home.activation.syncClaudeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_CONFIG="$HOME/.claude.json"
    OVERLAY_FILE="${./dotfiles/claude/config-overlay.json}"

    # Only proceed if jq is available
    if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
      # Create .claude.json if it doesn't exist
      if [[ ! -f "$CLAUDE_CONFIG" ]]; then
        echo "Creating new $CLAUDE_CONFIG..."
        echo '{}' > "$CLAUDE_CONFIG"
      fi

      # Create backup before modification
      BACKUP_FILE="''${CLAUDE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
      ${lib.getExe' pkgs.coreutils "cp"} "$CLAUDE_CONFIG" "$BACKUP_FILE"

      # Merge overlay into existing config using jq
      # This preserves all existing fields and only updates permissions and mcpServers
      ${lib.getExe' pkgs.jq "jq"} -s '.[0] * .[1]' "$CLAUDE_CONFIG" "$OVERLAY_FILE" | \
        ${lib.getExe' pkgs.moreutils "sponge"} "$CLAUDE_CONFIG"

      echo "✓ Claude Code configuration synced (backup: $BACKUP_FILE)"
    else
      echo "⚠ jq not found, skipping Claude config sync"
    fi
  '';

  # Packages
  imports =
    [
      ./modules/apps.nix
      ./modules/language.nix
      ./modules/env.nix
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
