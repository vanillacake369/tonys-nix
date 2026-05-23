# OpenAI Codex CLI configuration
# Contract implementation: logic verifier role with log-only reasoning
{
  config,
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};
  mcpAdapt = import ../../lib/mcp-adapters.nix {inherit lib;} config.programs.mcp.servers;

  # Merge policy-generated hooks with base hooks (SSoT: lib/agent-policy/agent-provider-hooks.nix)
  baseHooksLib = import ../../lib/agent-policy/agent-provider-hooks.nix {inherit lib;};
  policyHooks = config.agentPolicy._assembledHooks.codex or {};
  mergedHooks = baseHooksLib.mergeHooks baseHooksLib.codex policyHooks;

  codexSettings = {
    hooks = mergedHooks;
    mcp_servers = mcpAdapt.codex;
  };

  configFile = tomlFormat.generate "codex-config" codexSettings;
in {
  # Contract: Codex is the logic verifier — log-only reasoning
  agentPolicy.providers.codex = {
    enable = lib.mkDefault config.programs.codex.enable;

    # (A) Log-only reasoning — verification traces saved, not shown
    reasoning.mode = "log-only";
    reasoning.traceDir = "/tmp/agent-traces";

    # Hook format
    hooks.format = "codex";
    hooks.outputPath = "~/.codex/config.toml";
    hooks.timeout = 5;
  };

  programs.codex = {
    enable = true;
    settings = {};
    custom-instructions = builtins.readFile ../../dotfiles/shared/AGENTS.md;
  };

  home.activation.syncCodexConfig = sync.mkFileCopy {
    name = "codex-config";
    target = "$HOME/.codex/config.toml";
    source = "${configFile}";
  };
}
