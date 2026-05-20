# Claude Code configuration (no official home-manager module)
{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};
  mcpAdapt = import ../../lib/mcp-adapters.nix {inherit lib;} config.programs.mcp.servers;

  mcpSourceFile = jsonFormat.generate "claude-mcp.json" {
    mcpServers = mcpAdapt.claude;
  };
in {
  home.file = {
    ".claude/commands".source = ../../dotfiles/claude/commands;
    ".claude/AGENTS.md".source = ../../dotfiles/shared/AGENTS.md;
    ".claude/agents".source = ../../dotfiles/claude/agents;
    ".claude/skills".source = ../../dotfiles/claude/skills;
    ".claude/hooks".source = ../../dotfiles/claude/hooks;
  };

  home.activation.syncClaudeMcp = sync.mkJsonSync {
    name = "claude-mcp";
    target = "$HOME/.claude.json";
    source = "${mcpSourceFile}";
  };

  home.activation.syncClaudeSettings = sync.mkJsonSync {
    name = "claude-settings";
    target = "$HOME/.claude/settings.json";
    source = "${../../dotfiles/claude/settings.json}";
  };
}
