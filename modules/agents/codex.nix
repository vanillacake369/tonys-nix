# OpenAI Codex CLI configuration
# Package: nixpkgs (binary cache)
# MCP: manually merged (activation script for writable config)
# Instructions: shared/AGENTS.md (SSoT)
{
  config,
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};

  mcpServers = lib.mapAttrs (
    _: srv:
      (lib.removeAttrs srv ["disabled" "headers"])
      // (lib.optionalAttrs (srv ? headers && !(srv ? http_headers)) {
        http_headers = srv.headers;
      })
      // {enabled = !(srv.disabled or false);}
  ) config.programs.mcp.servers;

  codexSettings = {
    hooks.Stop = [
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/agent-notify.sh codex";
            timeout = 5;
          }
        ];
      }
    ];
    mcp_servers = mcpServers;
  };

  configFile = tomlFormat.generate "codex-config" codexSettings;
in {
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
