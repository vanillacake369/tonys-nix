# OpenAI Codex CLI configuration
# Contract implementation: logic verifier role with log-only reasoning
{
  config,
  lib,
  pkgs,
  ...
}: let
  toml = pkgs.formats.toml {};
  providerSettings = import ./provider-settings.nix {inherit config lib pkgs;};
  codexBindings = import ./codex-bindings.nix {inherit lib;};
  sharedContext = builtins.readFile ../../dotfiles/shared/AGENTS.md;
  model = "gpt-5.5";
  tuiSettings = {
    status_line = [
      "model-with-reasoning"
      "current-dir"
      "git-branch"
      "permissions"
      "five-hour-limit"
      "weekly-limit"
      "task-progress"
    ];
    status_line_use_colors = true;
  };
in {
  # Contract: Codex is the logic verifier — log-only reasoning
  agentPolicy.providers.codex = {
    enable = lib.mkDefault config.programs.codex.enable;

    # (A) Log-only reasoning — verification traces saved, not shown
    reasoning.mode = "log-only";
    reasoning.traceDir = "/tmp/agent-traces";
  };

  agentPolicy._providerRuntime.codex.hooks = {
    format = "codex";
    timeout = 5;
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = false;
    context = codexBindings.mkContext sharedContext;
    skills = codexBindings.skills;
    rules.default = ''
      prefix_rule(pattern=["nix", "fmt"], decision="allow")
      prefix_rule(pattern=["nix", "flake", "check"], decision="allow")
      prefix_rule(pattern=["nix", "eval"], decision="allow")
    '';
    settings = lib.mkForce {};
  };

  home.file =
    lib.mapAttrs' (name: agent: {
      name = ".codex/agents/${name}.toml";
      value.source = toml.generate "codex-agent-${name}.toml" agent;
    })
    codexBindings.customAgents;

  home.activation.syncCodexConfig = providerSettings.mkSettingsSync {
    provider = "codex";
    format = "toml";
    fileName = "codex-config.toml";
    syncName = "codex-config";
    target = "$HOME/.codex/config.toml";
    type = "toml";
    baseHooks = providerSettings.providerHooks.codex;
    preserveTomlKeys = [
      "hooks.state"
      "projects"
    ];
    render = {
      hooks,
      mcp,
    }:
      codexBindings.mkSettings {inherit hooks mcp;}
      // {
        inherit model;
        tui = tuiSettings;
      };
  };
}
