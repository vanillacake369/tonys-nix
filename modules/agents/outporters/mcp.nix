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

  clean = value: lib.filterAttrs (_: v: v != {}) (removeNulls value);

  internalAttrs = [
    "bearerTokenEnvVar"
    "disabled"
    "enabled"
    "headers"
    "envHttpHeaders"
    "transport"
  ];

  claudeInternalAttrs = [
    "bearerTokenEnvVar"
    "disabled"
    "enabled"
    "envHttpHeaders"
    "transport"
  ];

  stdioAttrs = [
    "args"
    "command"
    "cwd"
    "env"
  ];

  renderCodex = srv: let
    hasUrl = srv ? url && srv.url != null;
    attrsToRemove =
      internalAttrs
      ++ lib.optionals hasUrl stdioAttrs;
    base =
      removeNulls (lib.removeAttrs srv attrsToRemove)
      // (lib.optionalAttrs (srv ? headers && srv.headers != {} && !(srv ? http_headers)) {
        http_headers = removeNulls srv.headers;
      })
      // (lib.optionalAttrs (srv ? bearerTokenEnvVar) {
        bearer_token_env_var = srv.bearerTokenEnvVar;
      })
      // (lib.optionalAttrs (srv ? envHttpHeaders && srv.envHttpHeaders != {}) {
        env_http_headers = removeNulls srv.envHttpHeaders;
      })
      // {enabled = !(srv.disabled or false);};
  in
    clean base;

  renderGemini = srv:
    if srv ? command && srv.command != null
    then
      clean {
        inherit (srv) command;
        args = srv.args or [];
        env = srv.env or null;
        cwd = srv.cwd or null;
        timeout = srv.timeout or null;
        trust = srv.trust or null;
        description = srv.description or null;
        includeTools = srv.includeTools or null;
      }
    else if srv ? url && srv.url != null
    then
      clean {
        httpUrl = srv.url;
        headers = srv.headers or null;
        timeout = srv.timeout or null;
        trust = srv.trust or null;
        description = srv.description or null;
        includeTools = srv.includeTools or null;
      }
    else {};

  renderClaude = srv:
    if srv ? command && srv.command != null
    then clean ((lib.removeAttrs srv claudeInternalAttrs) // {type = "stdio";})
    else if srv ? url && srv.url != null
    then clean ((lib.removeAttrs srv (claudeInternalAttrs ++ stdioAttrs)) // {type = "http";})
    else {};
in {
  codex = lib.mapAttrs (_: renderCodex) servers;

  gemini = lib.mapAttrs (_: renderGemini) servers;

  claude = lib.mapAttrs (_: renderClaude) servers;
}
