# Claude Code configuration (no official home-manager module)
# Contract implementation: orchestrator role with full policy enforcement
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

  # Merge policy-generated hooks into base settings
  baseHooksLib = import ../../lib/agent-policy/agent-provider-hooks.nix {inherit lib;};
  baseSettings = builtins.fromJSON (builtins.readFile ../../dotfiles/claude/settings.json);
  policyHooks = config.agentPolicy._assembledHooks.claude or {};
  mergedHooks = baseHooksLib.mergeHooks (baseSettings.hooks or {}) policyHooks;

  finalSettings = baseSettings // {hooks = mergedHooks;};
  settingsFile = jsonFormat.generate "claude-settings.json" finalSettings;
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
    strategyLint.requiredSections = ["pre-mortem" "tradeoffs" "peer-review"];
    strategyLint.peerReviewProvider = "gemini";
    strategyLint.strategyPath = "/tmp/agent-strategy";

    # Hook format
    hooks.format = "claude";
    hooks.outputPath = "~/.claude/settings.json";
    hooks.timeout = 5;
  };

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
    source = "${settingsFile}";
  };
}
