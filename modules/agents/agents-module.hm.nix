# Multi-provider AI agent orchestration
# Claude Code (orchestrator) + Codex + Gemini via cli-proxy-api
# Agent Policy Contract: modules/agents/policy-assembler.nix provides the IoC assembler
{
  imports = [
    ./policy-assembler.nix
    ./agents-mcp.nix
    ./providers/claude/module.nix
    ./providers/codex/module.nix
    ./providers/gemini/module.nix
    ./agents-proxy.nix
  ];
}
