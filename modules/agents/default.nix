# Multi-provider AI agent orchestration
# Claude Code (orchestrator) + Codex + Gemini via cli-proxy-api
{
  imports = [
    ./mcp.nix
    ./claude.nix
    ./codex.nix
    ./gemini.nix
    ./proxy.nix
  ];
}
