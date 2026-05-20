# Claude Code configuration (no official home-manager module)
# Dotfiles: commands, agents, skills symlinked
# MCP: synced to ~/.claude.json via activation script
# Settings: synced to ~/.claude/settings.json via activation script
{
  config,
  lib,
  pkgs,
  ...
}: let
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};
in {
  home.file = {
    ".claude/commands".source = ../../dotfiles/claude/commands;
    ".claude/AGENTS.md".source = ../../dotfiles/shared/AGENTS.md;
    ".claude/agents".source = ../../dotfiles/claude/agents;
    ".claude/skills".source = ../../dotfiles/claude/skills;
    ".claude/hooks".source = ../../dotfiles/claude/hooks;
  };

  home.activation.syncClaudeMcp = sync.mkMcpSync {
    name = "claude-mcp";
    target = "$HOME/.claude.json";
    mcpServers = config.programs.mcp.servers;
  };

  home.activation.syncClaudeSettings = sync.mkJsonSync {
    name = "claude-settings";
    target = "$HOME/.claude/settings.json";
    source = "${../../dotfiles/claude/settings.json}";
  };
}
