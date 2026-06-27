# Adapts the canonical MCP server definitions (from mcp.nix) to each agent's format.
# SSoT: programs.mcp.servers → agent-specific config shape.
{lib}: servers: let
  removeNulls = value:
    if builtins.isAttrs value
    then
      lib.filterAttrsRecursive (_: v: v != null) (
        lib.mapAttrs (_: removeNulls) value
      )
    else if builtins.isList value
    then map removeNulls value
    else value;
in {
  # Codex: renames headers→http_headers, adds enabled flag, strips unknown fields
  codex =
    lib.mapAttrs (
      _: srv: let
        base = removeNulls (lib.removeAttrs srv ["disabled" "headers" "enabled"])
          // (lib.optionalAttrs (srv ? headers && srv.headers != {} && !(srv ? http_headers)) {
            http_headers = removeNulls srv.headers;
          })
          // {enabled = !(srv.disabled or false);};
      in
        lib.filterAttrs (_: v: v != {}) base
    )
    servers;

  # Gemini: only keeps command + args
  gemini =
    lib.mapAttrs (_: srv: {
      inherit (srv) command;
      args = srv.args or [];
    })
    servers;

  # Claude: passes through as-is (deep-merged into ~/.claude.json)
  claude = servers;
}
