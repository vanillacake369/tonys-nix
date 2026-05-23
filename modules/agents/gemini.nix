# Google Gemini CLI configuration
# Contract implementation: research/critic role with async handshake
{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};
  mcpAdapt = import ../../lib/mcp-adapters.nix {inherit lib;} config.programs.mcp.servers;

  # Merge policy-generated hooks with base hooks (SSoT: lib/agent-policy/agent-provider-hooks.nix)
  baseHooksLib = import ../../lib/agent-policy/agent-provider-hooks.nix {inherit lib;};
  policyHooks = config.agentPolicy._assembledHooks.gemini or {};
  mergedHooks = baseHooksLib.mergeHooks baseHooksLib.gemini policyHooks;

  geminiSettings = {
    mcpServers = mcpAdapt.gemini;
    hooks = mergedHooks;
  };

  settingsFile = jsonFormat.generate "gemini-cli-settings.json" geminiSettings;
in {
  # Contract: Gemini is the async research/critic agent
  agentPolicy.providers.gemini = {
    enable = lib.mkDefault config.programs.gemini-cli.enable;

    # (A) Verbose reasoning — research results fully visible
    reasoning.mode = "verbose";

    # (B) Async handshake — background strategy review
    async.enabled = true;
    async.handshakeProtocol = "fifo";
    async.backgroundTasks = ["strategy-review" "blindspot-audit" "impact-analysis"];
    async.fifoDir = "/tmp/agent-handshake";

    # Hook format
    hooks.format = "gemini";
    hooks.outputPath = "~/.gemini/settings.json";
    hooks.timeout = 5;
  };

  programs.gemini-cli = {
    enable = true;
    settings = {};
    context = {
      "GEMINI" = ../../dotfiles/shared/AGENTS.md;
    };
  };

  home.activation.syncGeminiSettings = sync.mkJsonSync {
    name = "gemini-settings";
    target = "$HOME/.gemini/settings.json";
    source = "${settingsFile}";
  };
}
