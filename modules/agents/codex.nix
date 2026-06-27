# OpenAI Codex CLI configuration
# Contract implementation: logic verifier role with log-only reasoning
{
  config,
  lib,
  pkgs,
  ...
}: let
  providerRuntime = import ./provider-runtime.nix {inherit config lib pkgs;};
  codexBindings = import ./codex-bindings.nix {inherit lib;};
  sharedContext = builtins.readFile ../../dotfiles/shared/AGENTS.md;
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
    profiles = codexBindings.profiles;
    settings = lib.mkForce {};
  };

  home.activation.syncCodexConfig = providerRuntime.mkSettingsSync {
    provider = "codex";
    format = "toml";
    fileName = "codex-config.toml";
    syncName = "codex-config";
    target = "$HOME/.codex/config.toml";
    type = "toml";
    baseHooks = providerRuntime.providerHooks.codex;
    render = {
      hooks,
      mcp,
    }:
      codexBindings.mkSettings {inherit hooks mcp;};
  };
}
