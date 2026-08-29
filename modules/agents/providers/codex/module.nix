# OpenAI Codex CLI configuration
# Contract implementation: logic verifier role with log-only reasoning
{
  config,
  lib,
  pkgs,
  ...
}: let
  toml = pkgs.formats.toml {};
  providerSettings = import ../../outporters/provider-settings.nix {inherit config lib pkgs;};
  codexBindings = import ./bindings.nix {inherit lib;};
  source = import ../../source-of-truth {inherit lib;};
in {
  programs.codex = {
    enable = true;
    enableMcpIntegration = false;
    context = codexBindings.mkContext source.sharedGuide;
    inherit (codexBindings) skills;
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
    baseHooks = source.providerHooks.codex;
    preserveTomlKeys = [
      "hooks.state"
      "projects"
    ];
    obsoleteFiles = [
      "hooks.json"
    ];
    render = {
      hooks,
      mcp,
    }:
      codexBindings.mkSettings {inherit hooks mcp;}
      // {
        model = source.codexModel;
        tui = source.codexTui;
      };
  };
}
