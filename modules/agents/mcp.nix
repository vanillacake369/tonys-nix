# MCP server definitions (Single Source of Truth)
# Consumed by: codex (enableMcpIntegration), gemini (settings.mcpServers), claude (activation script)
{...}: {
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        command = "npx";
        args = ["-y" "@upstash/context7-mcp@latest"];
      };
      playwright = {
        command = "npx";
        args = ["-y" "@executeautomation/playwright-mcp-server"];
      };
    };
  };
}
