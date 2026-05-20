# Adapts the canonical MCP server definitions (from mcp.nix) to each agent's format.
# SSoT: programs.mcp.servers → agent-specific config shape.
{lib}: servers: {
  # Codex: renames headers→http_headers, adds enabled flag, strips unknown fields
  codex =
    lib.mapAttrs (
      _: srv:
        (lib.removeAttrs srv ["disabled" "headers"])
        // (lib.optionalAttrs (srv ? headers && !(srv ? http_headers)) {
          http_headers = srv.headers;
        })
        // {enabled = !(srv.disabled or false);}
    )
    servers;

  # Gemini: only keeps command + args
  gemini =
    lib.mapAttrs (_: srv: {
      command = srv.command;
      args = srv.args or [];
    })
    servers;

  # Claude: passes through as-is (deep-merged into ~/.claude.json)
  claude = servers;
}
