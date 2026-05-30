# Claude Code configuration (no official home-manager module)
# Contract implementation: orchestrator role with full policy enforcement
{
  config,
  lib,
  pkgs,
  ...
}: let
  providerRuntime = import ./provider-runtime.nix {inherit config lib pkgs;};

  mcpSourceFile = providerRuntime.mkFile {
    format = "json";
    name = "claude-mcp.json";
    value = {
      mcpServers = providerRuntime.mcp.claude;
    };
  };

  baseSettings = builtins.fromJSON (builtins.readFile ../../dotfiles/claude/settings.json);
in {
  # Contract: Claude is the orchestrator — full policy suite
  agentPolicy.providers.claude = {
    enable = lib.mkDefault true;

    # (A) Silent reasoning — orchestrator shows decisions, not chain-of-thought
    reasoning.mode = "silent";
    reasoning.traceDir = "/tmp/agent-traces";

    # (D) Live verification oracle
    oracle.enabled = true;
    oracle.healthChecks = [
      {
        command = "nix flake check --no-build 2>&1 | head -20";
        pattern = ".*\\.nix$";
        timeout = 60;
      }
    ];
    oracle.streamAnalysis = true;

    # (E) Phase state machine enforcement
    phases.enforced = true;
    phases.stateDir = "/tmp/claude-complexity";
    phases.gatedTools = ["Write" "Edit" "NotebookEdit"];

    # (F) Strategy lint gate with Gemini peer review
    strategyLint.enabled = true;
    strategyLint.requiredSections = ["pre-mortem" "tradeoffs" "peer-review" "grilled-decisions"];
    strategyLint.peerReviewProvider = "gemini";
    strategyLint.strategyPath = "/tmp/agent-strategy";
  };

  agentPolicy._providerRuntime.claude.hooks = {
    format = "claude";
    timeout = 5;
  };

  home.file = {
    ".claude/commands".source = ../../dotfiles/claude/commands;
    ".claude/AGENTS.md".source = ../../dotfiles/shared/AGENTS.md;
    ".claude/agents".source = ../../dotfiles/claude/agents;
    ".claude/skills".source = ../../dotfiles/claude/skills;
    ".claude/hooks".source = ../../dotfiles/claude/hooks;
  };

  home.activation.syncClaudeMcp = providerRuntime.mkSync {
    name = "claude-mcp";
    target = "$HOME/.claude.json";
    source = "${mcpSourceFile}";
  };

  home.activation.syncClaudeSettings = providerRuntime.mkSettingsSync {
    provider = "claude";
    format = "json";
    fileName = "claude-settings.json";
    syncName = "claude-settings";
    target = "$HOME/.claude/settings.json";
    baseHooks = baseSettings.hooks or {};
    render = {hooks, ...}: baseSettings // {inherit hooks;};
  };
}
