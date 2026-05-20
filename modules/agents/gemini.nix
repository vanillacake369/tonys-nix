# Google Gemini CLI configuration
# Package: nixpkgs (binary cache)
# MCP: manually merged (activation script for writable config)
# Instructions: shared/AGENTS.md -> ~/.gemini/GEMINI.md
{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  sync = import ../../lib/sync-mutable-config.nix {inherit lib pkgs;};

  geminiSettings = {
    mcpServers =
      lib.mapAttrs (_: srv: {
        command = srv.command;
        args = srv.args or [];
      })
      config.programs.mcp.servers;
    hooks.AfterAgent = [
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/agent-notify.sh gemini";
            timeout = 5000;
          }
        ];
      }
    ];
  };

  settingsFile = jsonFormat.generate "gemini-cli-settings.json" geminiSettings;
in {
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
