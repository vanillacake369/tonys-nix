# MCP server definitions (Single Source of Truth)
# Consumed by the active Codex provider through the provider-native outporter.
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
      ticktick = {
        url = "https://mcp.ticktick.com";
        transport = "streamable-http";
        bearerTokenEnvVar = "TICKTICK_MCP_TOKEN";
      };
      atlassian = {
        # Official Atlassian Remote MCP v2. OAuth is the default authentication
        # path (`codex mcp login atlassian`). For non-interactive use, the
        # launcher may provide an Authorization header through this env var.
        url = "https://mcp.atlassian.com/v2/mcp";
        transport = "streamable-http";
        envHttpHeaders.Authorization = "ATLASSIAN_MCP_AUTHORIZATION";
      };
    };
  };
}
