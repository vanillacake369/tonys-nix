# OpenAI Codex CLI configuration
# Package: nixpkgs (binary cache)
# MCP: manually merged (activation script for writable config)
# Instructions: shared/AGENTS.md (SSoT)
{
  config,
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};

  # Build MCP servers from shared programs.mcp config
  mcpServers = lib.mapAttrs (
    _: srv:
      (lib.removeAttrs srv ["disabled" "headers"])
      // (lib.optionalAttrs (srv ? headers && !(srv ? http_headers)) {
        http_headers = srv.headers;
      })
      // {enabled = !(srv.disabled or false);}
  ) config.programs.mcp.servers;

  # Full settings (hooks + MCP)
  codexSettings = {
    hooks.Stop = [
      {
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/agent-notify.sh codex";
            timeout = 5;
          }
        ];
      }
    ];
    mcp_servers = mcpServers;
  };

  configFile = tomlFormat.generate "codex-config" codexSettings;
in {
  programs.codex = {
    enable = true;
    # Empty settings — we handle config via activation script for writability
    settings = {};
    custom-instructions = builtins.readFile ../../dotfiles/shared/AGENTS.md;
  };

  home.activation.syncCodexConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CONFIG_FILE="$HOME/.codex/config.toml"
    SOURCE_FILE="${configFile}"

    mkdir -p "$HOME/.codex"

    # Remove symlink if home-manager left one
    if [[ -L "$CONFIG_FILE" ]]; then
      rm "$CONFIG_FILE"
    fi

    if [[ -f "$CONFIG_FILE" ]]; then
      ${lib.getExe' pkgs.coreutils "cp"} "$CONFIG_FILE" "''${CONFIG_FILE}.backup"
    fi

    ${lib.getExe' pkgs.coreutils "cp"} "$SOURCE_FILE" "$CONFIG_FILE"
    ${lib.getExe' pkgs.coreutils "chmod"} u+w "$CONFIG_FILE"
  '';
}
