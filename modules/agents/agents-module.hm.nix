# Multi-provider AI agent orchestration
# Claude Code (orchestrator) + Codex + Gemini via cli-proxy-api
# Agent Policy Contract: modules/agents/policy-assembler.nix provides the IoC assembler
{
  imports = [
    ./policy-assembler.nix
    ./agents-mcp.nix
    ./claude.nix
    ./codex.nix
    ./gemini.nix
    ./agents-proxy.nix
  ];
}
