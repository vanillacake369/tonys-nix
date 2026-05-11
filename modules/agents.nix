# Multi-provider AI agent configuration
# SSoT: shared AGENTS.md + programs.mcp.servers
# Providers: Claude Code, OpenAI Codex, Google Gemini CLI
{
  lib,
  pkgs,
  ...
}: let
  sharedAgentsMd = ../dotfiles/shared/AGENTS.md;

  # Shared MCP server definitions (SSoT)
  # programs.mcp.servers feeds into codex (via enableMcpIntegration)
  # and gemini-cli (manually merged into settings.mcpServers)
  mcpServers = {
    context7 = {
      command = "npx";
      args = ["-y" "@upstash/context7-mcp@latest"];
    };
    playwright = {
      command = "npx";
      args = ["-y" "@executeautomation/playwright-mcp-server"];
    };
  };
in {
  # ── MCP Servers (SSoT) ──────────────────────────────────────────
  programs.mcp = {
    enable = true;
    servers = mcpServers;
  };

  # ── OpenAI Codex CLI ────────────────────────────────────────────
  programs.codex = {
    enable = true;
    enableMcpIntegration = true; # auto-injects programs.mcp.servers
    custom-instructions = builtins.readFile sharedAgentsMd;
  };

  # ── Google Gemini CLI ───────────────────────────────────────────
  programs.gemini-cli = {
    enable = true;
    settings = {
      # Inject MCP servers directly (no enableMcpIntegration available)
      mcpServers = lib.mapAttrs (_name: srv: {
        command = srv.command;
        args = srv.args or [];
      }) mcpServers;
    };
    context = {
      "GEMINI" = sharedAgentsMd; # deploys as ~/.gemini/GEMINI.md
    };
  };

  # ── Claude Code (no official module) ────────────────────────────
  home.file = {
    ".claude/commands".source = ../dotfiles/claude/commands;
    ".claude/AGENTS.md".source = sharedAgentsMd; # SSoT
    ".claude/agents".source = ../dotfiles/claude/agents;
    ".claude/skills".source = ../dotfiles/claude/skills;
  };

  # Sync MCP servers to ~/.claude.json (Claude has no official module)
  home.activation.syncClaudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CLAUDE_CONFIG="$HOME/.claude.json"
    MCP_JSON='${builtins.toJSON {inherit mcpServers;}}'

    if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
      if [[ ! -f "$CLAUDE_CONFIG" ]]; then
        echo '{}' > "$CLAUDE_CONFIG"
      fi

      ${lib.getExe' pkgs.coreutils "cp"} "$CLAUDE_CONFIG" "''${CLAUDE_CONFIG}.backup"

      # Replace mcpServers entirely (delete existing, then merge)
      echo "$MCP_JSON" | ${lib.getExe' pkgs.jq "jq"} -s '(.[0] | del(.mcpServers)) * .[1]' "$CLAUDE_CONFIG" - | \
        ${lib.getExe' pkgs.moreutils "sponge"} "$CLAUDE_CONFIG"

      echo "Claude Code MCP servers synced to ~/.claude.json"
    fi
  '';

  # Sync settings.json to ~/.claude/settings.json
  home.activation.syncClaudeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SETTINGS_FILE="$HOME/.claude/settings.json"
    SOURCE_FILE="${../dotfiles/claude/settings.json}"

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
