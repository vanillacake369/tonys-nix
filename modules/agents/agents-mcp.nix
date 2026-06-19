# MCP server definitions (Single Source of Truth)
# Consumed by: codex (enableMcpIntegration), gemini (settings.mcpServers), claude (activation script)
#
# Versioning policy: MCP servers run via `npx ...@latest` and are therefore NOT
# pinned by the Nix flake. This is intentional — these are runtime sidecars that
# benefit from upstream fixes and are not part of the reproducible system closure.
# The tradeoff (a remote npm fetch at first launch, version drift across machines)
# is accepted. Pin a specific version here if reproducibility ever matters more
# than freshness.
_: {
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        command = "npx";
        args = ["-y" "@upstash/context7-mcp@latest"];
      };
      playwright = {
        command = "npx";
        args = ["-y" "@playwright/mcp@latest"];
      };
    };
  };
}
