{
  pkgs,
  config,
  lib,
  isWsl,
  ...
}: {
  home.sessionVariables =
    {
      # Java
      JAVA_HOME = "${pkgs.zulu17}";

      # Google Drive MCP credentials
      GDRIVE_CREDENTIALS_PATH = "${config.home.homeDirectory}/dev/tonys-mcp-claude-code-credentials.json";
      GDRIVE_OAUTH_PATH = "${config.home.homeDirectory}/dev/tonys-mcp-claude-code.json";

      # JIRA MCP credentials (URL and username are static)
      JIRA_URL = "https://hamalab.atlassian.net";
      JIRA_USERNAME = "lonelynight1026@hamagroups.io";
    }
    // lib.optionalAttrs isWsl {
      # WSL X server display configuration
      DISPLAY = ":0.0";
      LIBGL_ALWAYS_INDIRECT = "1";
    };

  # ZSH initialization for dynamic environment variables
  # Load JIRA token from .md file at shell startup
  programs.zsh.initContent = ''
    # Load JIRA token from markdown file
    JIRA_TOKEN_FILE="${config.home.homeDirectory}/dev/tonys-jira-mcp-token.md"
    if [ -f "$JIRA_TOKEN_FILE" ]; then
      export JIRA_TOKEN=$(cat "$JIRA_TOKEN_FILE" | tr -d '[:space:]')
    fi

    # Load POSTGRES_URL from markdown file
    POSTGRES_FILE="${config.home.homeDirectory}/dev/tonys-postgresql.md"
    if [ -f "$POSTGRES_FILE" ]; then
      export POSTGRES_URL=$(cat "$POSTGRES_FILE" | tr -d '[:space:]')
    fi

    # Load KAKAOPAY from markdown file
    KAKAOPAY_FILE="${config.home.homeDirectory}/dev/tonys-kakaopay.md"
    if [ -f "$KAKAOPAY_FILE" ]; then
      export KAKAOPAY_SECRET_KEY=$(cat "$KAKAOPAY_FILE" | tr -d '[:space:]')
    fi
  '';
}
