{
  pkgs,
  config,
  ...
}: {
  home.sessionVariables = {
    # Java
    JAVA_HOME = "${pkgs.zulu17}";

    # Google Drive MCP credentials
    GDRIVE_CREDENTIALS_PATH = "${config.home.homeDirectory}/dev/tonys-mcp-claude-code-credentials.json";
    GDRIVE_OAUTH_PATH = "${config.home.homeDirectory}/dev/tonys-mcp-claude-code.json";
  };
}
