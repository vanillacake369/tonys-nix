# OpenAI Codex CLI configuration
# Contract implementation: logic verifier role with log-only reasoning
{
  config,
  lib,
  pkgs,
  ...
}: let
  providerRuntime = import ./provider-runtime.nix {inherit config lib pkgs;};
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
    settings = {};
    context = builtins.readFile ../../dotfiles/shared/AGENTS.md;
  };

  home.activation.syncCodexConfig = providerRuntime.mkSettingsSync {
    provider = "codex";
    format = "toml";
    type = "copy";
    fileName = "codex-config";
    syncName = "codex-config";
    target = "$HOME/.codex/config.toml";
    baseHooks = providerRuntime.providerHooks.codex;
    render = {
      hooks,
      mcp,
    }: {
      inherit hooks;
      mcp_servers = mcp;
    };
  };
}
