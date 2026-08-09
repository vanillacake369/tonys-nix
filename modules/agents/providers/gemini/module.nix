# Google Gemini CLI configuration
# Contract implementation: research/critic role with async handshake
{
  config,
  lib,
  pkgs,
  ...
}: let
  providerSettings = import ../../outporters/provider-settings.nix {inherit config lib pkgs;};
  source = import ../../source-of-truth {inherit lib;};
in {
  programs.antigravity-cli = {
    enable = true;
    settings = {};
    context = {
      "GEMINI" = source.sharedGuidePath;
      "AGENT_WORKFLOWS" = source.workflows.sharedGuide;
    };
  };

  home.activation.syncGeminiSettings = providerSettings.mkSettingsSync {
    provider = "gemini";
    format = "json";
    fileName = "antigravity-cli-settings.json";
    syncName = "gemini-settings";
    target = "$HOME/.gemini/settings.json";
    baseHooks = source.providerHooks.gemini;
    render = {
      hooks,
      mcp,
    }: {
      mcpServers = mcp;
      inherit hooks;
    };
  };
}
