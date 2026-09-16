# Claude Code configuration (no official home-manager module)
# Contract implementation: orchestrator role with full policy enforcement
{
  config,
  lib,
  pkgs,
  ...
}: let
  providerSettings = import ../../outporters/provider-settings.nix {inherit config lib pkgs;};
  source = import ../../source-of-truth {inherit lib;};

  mcpSourceFile = providerSettings.mkFile {
    format = "json";
    name = "claude-mcp.json";
    value = {
      mcpServers = providerSettings.mcp.claude;
    };
  };

  baseSettings = builtins.fromJSON (builtins.readFile ./settings.json);
in {
  home.file = {
    ".claude/commands".source = ../../source-of-truth/workflows/commands;
    ".claude/WORKFLOWS.md".text = source.workflows.sharedGuide;
    ".claude/AGENTS.md".source = source.sharedGuidePath;
    ".claude/agents".source = ./agents;
    ".claude/skills".source = ./skills;
    ".claude/hooks".source = ./hooks;
  };

  home.activation.syncClaudeMcp = providerSettings.mkSync {
    name = "claude-mcp";
    target = "$HOME/.claude.json";
    source = "${mcpSourceFile}";
  };

  home.activation.syncClaudeSettings = providerSettings.mkSettingsSync {
    provider = "claude";
    format = "json";
    fileName = "claude-settings.json";
    syncName = "claude-settings";
    target = "$HOME/.claude/settings.json";
    baseHooks = baseSettings.hooks or {};
    render = {hooks, ...}: baseSettings // {inherit hooks;};
  };
}
