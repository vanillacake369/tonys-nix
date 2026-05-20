# Google Gemini CLI configuration
# Package: nixpkgs (binary cache)
# MCP: manually merged (activation script for writable config)
# Instructions: shared/AGENTS.md → ~/.gemini/GEMINI.md
{
  config,
  lib,
  pkgs,
  ...
}: let
  jsonFormat = pkgs.formats.json {};

  # Build settings with MCP servers and hooks
  geminiSettings = {
    mcpServers = lib.mapAttrs (_: srv: {
      command = srv.command;
      args = srv.args or [];
    }) config.programs.mcp.servers;
    hooks.AfterAgent = [
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/agent-notify.sh gemini";
            timeout = 5000;
          }
        ];
      }
    ];
  };

  settingsFile = jsonFormat.generate "gemini-cli-settings.json" geminiSettings;
in {
  programs.gemini-cli = {
    enable = true;
    # Empty settings — we handle config via activation script for writability
    settings = {};
    context = {
      "GEMINI" = ../../dotfiles/shared/AGENTS.md;
    };
  };

  home.activation.syncGeminiSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    SETTINGS_FILE="$HOME/.gemini/settings.json"
    SOURCE_FILE="${settingsFile}"

    mkdir -p "$HOME/.gemini"

    # Remove symlink if home-manager left one
    if [[ -L "$SETTINGS_FILE" ]]; then
      rm "$SETTINGS_FILE"
    fi

    if [[ -f "$SETTINGS_FILE" ]]; then
      ${lib.getExe' pkgs.coreutils "cp"} "$SETTINGS_FILE" "''${SETTINGS_FILE}.backup"
      
      # Merge existing settings with new source using jq
      if command -v ${lib.getExe' pkgs.jq "jq"} &> /dev/null; then
        ${lib.getExe' pkgs.jq "jq"} -s '.[0] * .[1]' "$SETTINGS_FILE" "$SOURCE_FILE" | \
          ${lib.getExe' pkgs.moreutils "sponge"} "$SETTINGS_FILE"
      else
        ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
      fi
    else
      ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$SETTINGS_FILE"
    fi

    ${lib.getExe' pkgs.coreutils "chmod"} u+w "$SETTINGS_FILE"
  '';
}
