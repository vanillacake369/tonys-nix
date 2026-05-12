# Google Gemini CLI configuration
# Package: llm-agents.nix (daily updated)
# MCP: manually injected (no enableMcpIntegration)
# Instructions: shared/AGENTS.md → ~/.gemini/GEMINI.md
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.gemini-cli = {
    enable = true;
    settings = {
      mcpServers = lib.mapAttrs (_: srv: {
        command = srv.command;
        args = srv.args or [];
      }) config.programs.mcp.servers;
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
    context = {
      "GEMINI" = ../../dotfiles/shared/AGENTS.md;
    };
  };
}
