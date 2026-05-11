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
    package = pkgs.llm-agents.gemini-cli;
    settings = {
      mcpServers = lib.mapAttrs (_: srv: {
        command = srv.command;
        args = srv.args or [];
      }) config.programs.mcp.servers;
    };
    context = {
      "GEMINI" = ../../dotfiles/shared/AGENTS.md;
    };
  };
}
