# Provider-native MCP shapes rendered from programs.mcp.servers.
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
  codex =
    lib.mapAttrs (
      _: srv: let
        base =
          removeNulls (lib.removeAttrs srv ["disabled" "headers" "enabled"])
          // (lib.optionalAttrs (srv ? headers && srv.headers != {} && !(srv ? http_headers)) {
            http_headers = removeNulls srv.headers;
          })
          // {enabled = !(srv.disabled or false);};
      in
        lib.filterAttrs (_: v: v != {}) base
    )
    servers;

  gemini =
    lib.mapAttrs (_: srv: {
      inherit (srv) command;
      args = srv.args or [];
    })
    servers;

  claude = servers;
}
