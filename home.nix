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

      # Claude configuration - static files only (settings.json and mcp-servers.json handled by activation scripts)
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
      ".config/karabiner/karabiner.json" = {
        source = ./dotfiles/karabiner/karabiner.json;
        force = true;
      };

      # Window manager :: Aerospace
      ".config/aerospace".source = ./dotfiles/aerospace;
    };

  # Activation scripts to sync Claude Code configuration
  # Syncs mcp-servers.json → ~/.claude.json and settings.json → ~/.claude/settings.json

  # Sync mcp-servers and mcpServers to ~/.claude.json
  home.activation.syncClaudePermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_CONFIG="$HOME/.claude.json"
    PERMISSIONS_FILE="${./dotfiles/claude/mcp-servers.json}"

    # Only proceed if jq is available
    if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
      # Create .claude.json if it doesn't exist
      if [[ ! -f "$CLAUDE_CONFIG" ]]; then
        echo "Creating new $CLAUDE_CONFIG..."
        echo '{}' > "$CLAUDE_CONFIG"
      fi

      # Create backup before modification (single file, overwrite)
      ${lib.getExe' pkgs.coreutils "cp"} "$CLAUDE_CONFIG" "''${CLAUDE_CONFIG}.backup"

      # Replace mcpServers with source file (delete existing, then merge)
      # This ensures removed servers are actually deleted
      ${lib.getExe' pkgs.jq "jq"} -s '(.[0] | del(.mcpServers)) * .[1]' "$CLAUDE_CONFIG" "$PERMISSIONS_FILE" | \
        ${lib.getExe' pkgs.moreutils "sponge"} "$CLAUDE_CONFIG"

      echo "✓ Claude Code mcp-servers synced to ~/.claude.json"
    else
      echo "⚠ jq not found, skipping Claude mcp-servers sync"
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
        # Ensure file is writable before modification
        ${lib.getExe' pkgs.coreutils "chmod"} u+w "$SETTINGS_FILE"

        # Merge settings (existing user settings take precedence)
        ${lib.getExe' pkgs.jq "jq"} -s '.[0] * .[1]' "$SETTINGS_FILE" "$SOURCE_FILE" | \
          ${lib.getExe' pkgs.moreutils "sponge"} "$SETTINGS_FILE"

        echo "✓ Claude Code settings merged to ~/.claude/settings.json"
      else
        # No existing file, copy fresh
        ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
        echo "✓ Claude Code settings.json created"
      fi
    else
      # Ensure file is writable if it exists
      [[ -f "$SETTINGS_FILE" ]] && ${lib.getExe' pkgs.coreutils "chmod"} u+w "$SETTINGS_FILE"
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
