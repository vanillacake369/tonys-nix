# OpenAI Codex CLI configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};
  mcpAdapt = import ../../lib/mcp-adapters.nix {inherit lib;} config.programs.mcp.servers;

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
    mcp_servers = mcpAdapt.codex;
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
