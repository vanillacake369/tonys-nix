# Google Gemini CLI configuration
# Contract implementation: research/critic role with async handshake
{
  config,
  lib,
  pkgs,
  ...
}: let
  providerRuntime = import ./provider-runtime.nix {inherit config lib pkgs;};
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
  };

  agentPolicy._providerRuntime.gemini.hooks = {
    format = "gemini";
    timeout = 5;
  };

  programs.gemini-cli = {
    enable = true;
    settings = {};
    context = {
      "GEMINI" = ../../dotfiles/shared/AGENTS.md;
    };
  };

  home.activation.syncGeminiSettings = providerRuntime.mkSettingsSync {
    provider = "gemini";
    format = "json";
    fileName = "gemini-cli-settings.json";
    syncName = "gemini-settings";
    target = "$HOME/.gemini/settings.json";
    baseHooks = providerRuntime.providerHooks.gemini;
    render = {
      hooks,
      mcp,
    }: {
      mcpServers = mcp;
      inherit hooks;
    };
  };
}
