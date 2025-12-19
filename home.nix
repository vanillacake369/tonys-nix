{
  lib,
  pkgs,
  isLinux,
  isDarwin,
  isWsl,
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

      # Claude configuration - static files only (settings.json and permissions.json handled by activation scripts)
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
      # Keymapper :: karabiner
      ".config/karabiner/karabiner.json".source = ./dotfiles/karabiner/karabiner.json;

      # Window manager :: Aerospace
      ".config/aerospace".source = ./dotfiles/aerospace;
    };

  # Activation scripts to sync Claude Code configuration
  # Syncs permissions.json → ~/.claude.json and settings.json → ~/.claude/settings.json

  # Sync permissions and mcpServers to ~/.claude.json
  home.activation.syncClaudePermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_CONFIG="$HOME/.claude.json"
    PERMISSIONS_FILE="${./dotfiles/claude/permissions.json}"

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

      # Merge permissions into existing config using jq
      # This preserves all existing fields and only updates permissions and mcpServers
      ${lib.getExe' pkgs.jq "jq"} -s '.[0] * .[1]' "$CLAUDE_CONFIG" "$PERMISSIONS_FILE" | \
        ${lib.getExe' pkgs.moreutils "sponge"} "$CLAUDE_CONFIG"

      echo "✓ Claude Code permissions synced to ~/.claude.json (backup: $BACKUP_FILE)"
    else
      echo "⚠ jq not found, skipping Claude permissions sync"
    fi
  '';

  # Sync settings.json to ~/.claude/settings.json
  home.activation.syncClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SETTINGS_FILE="$HOME/.claude/settings.json"
    SOURCE_FILE="${./dotfiles/claude/settings.json}"

    mkdir -p "$HOME/.claude"

    # Only proceed if jq is available
    if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
      if [[ -f "$SETTINGS_FILE" ]]; then
        # Create backup before modification
        BACKUP_FILE="''${SETTINGS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        ${lib.getExe' pkgs.coreutils "cp"} "$SETTINGS_FILE" "$BACKUP_FILE"

        # Merge settings (existing user settings take precedence)
        ${lib.getExe' pkgs.jq "jq"} -s '.[0] * .[1]' "$SETTINGS_FILE" "$SOURCE_FILE" | \
          ${lib.getExe' pkgs.moreutils "sponge"} "$SETTINGS_FILE"

        echo "✓ Claude Code settings merged to ~/.claude/settings.json (backup: $BACKUP_FILE)"
      else
        # No existing file, copy fresh
        ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
        echo "✓ Claude Code settings.json created"
      fi
    else
      # Fallback: simple copy without merge
      ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
      echo "✓ Claude Code settings.json copied (jq not available for merge)"
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
