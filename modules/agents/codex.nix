# OpenAI Codex CLI configuration
# Package: llm-agents.nix (daily updated)
# MCP: auto-injected via enableMcpIntegration
# Instructions: shared/AGENTS.md (SSoT)
{pkgs, ...}: {
  programs.codex = {
    enable = true;
    package = pkgs.llm-agents.codex;
    enableMcpIntegration = true;
    custom-instructions = builtins.readFile ../../dotfiles/shared/AGENTS.md;
  };
}
