# Claude Code configuration (no official home-manager module)
# Dotfiles: commands, agents, skills symlinked
# MCP: synced to ~/.claude.json via activation script
# Settings: synced to ~/.claude/settings.json via activation script
{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file = {
    ".claude/commands".source = ../../dotfiles/claude/commands;
    ".claude/AGENTS.md".source = ../../dotfiles/shared/AGENTS.md;
    ".claude/agents".source = ../../dotfiles/claude/agents;
    ".claude/skills".source = ../../dotfiles/claude/skills;
    ".claude/hooks".source = ../../dotfiles/claude/hooks;
  };

  home.activation.syncClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_CONFIG="$HOME/.claude.json"
    MCP_JSON='${builtins.toJSON {mcpServers = config.programs.mcp.servers;}}'

    if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
      if [[ ! -f "$CLAUDE_CONFIG" ]]; then
        echo '{}' > "$CLAUDE_CONFIG"
      fi

      ${lib.getExe' pkgs.coreutils "cp"} "$CLAUDE_CONFIG" "''${CLAUDE_CONFIG}.backup"

      echo "$MCP_JSON" | ${lib.getExe' pkgs.jq "jq"} -s '(.[0] | del(.mcpServers)) * .[1]' "$CLAUDE_CONFIG" - | \
        ${lib.getExe' pkgs.moreutils "sponge"} "$CLAUDE_CONFIG"
    fi
  '';

  home.activation.syncClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SETTINGS_FILE="$HOME/.claude/settings.json"
    SOURCE_FILE="${../../dotfiles/claude/settings.json}"

    mkdir -p "$HOME/.claude"

    if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
      if [[ -f "$SETTINGS_FILE" ]]; then
        ${lib.getExe' pkgs.coreutils "chmod"} u+w "$SETTINGS_FILE"
        ${lib.getExe' pkgs.jq "jq"} -s '.[0] * .[1]' "$SETTINGS_FILE" "$SOURCE_FILE" | \
          ${lib.getExe' pkgs.moreutils "sponge"} "$SETTINGS_FILE"
      else
        ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
      fi
    else
      [[ -f "$SETTINGS_FILE" ]] && ${lib.getExe' pkgs.coreutils "chmod"} u+w "$SETTINGS_FILE"
      ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
    fi
  '';
}
