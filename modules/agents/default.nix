# Multi-provider AI agent orchestration
# Claude Code (orchestrator) + Codex + Gemini via cli-proxy-api
# Agent Policy Contract: lib/agent-policy/policy.nix provides the IoC assembler
{
  imports = [
    ../../lib/agent-policy/policy.nix
    ./mcp.nix
    ./claude.nix
    ./codex.nix
    ./gemini.nix
    ./proxy.nix
  ];
}
