# Multi-provider AI agent orchestration
# Claude Code (orchestrator) + Codex + Gemini via cli-proxy-api
# Agent Policy Contract: lib/agent-policy/agent-assembler.nix provides the IoC assembler
{
  imports = [
    ../../lib/agent-policy/agent-assembler.nix
    ./agents-mcp.nix
    ./claude.nix
    ./codex.nix
    ./gemini.nix
    ./agents-proxy.nix
  ];
}
