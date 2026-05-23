# Adapts generated hook definitions to each provider's hook configuration format.
# SSoT pattern — mirrors lib/mcp-adapters.nix for hooks.
#
# Input: attrset of { <mixin-name>.<provider-name> = { event, matcher, script }; }
# Output: provider-specific hook config ready for settings injection.
{lib}: let
  # Group hooks by provider name across all mixins
  # Input:  { phase-gate.claude = {...}; path-guard.claude = {...}; ... }
  # Output: { claude = [ {...} {...} ]; gemini = [ {...} ]; ... }
  groupByProvider = allHooks: let
    mixinNames = lib.attrNames allHooks;
    # Flatten: [ { provider = "claude"; hook = {...}; } ... ]
    flat = lib.concatMap (mixin:
      lib.mapAttrsToList (provider: hook: {
        inherit provider;
        hook = hook // {inherit mixin;};
      }) (allHooks.${mixin} or {}))
    mixinNames;
  in
    lib.groupBy (x: x.provider) flat;

  # Group hooks by event within a provider's hook list
  groupByEvent = hookList:
    lib.groupBy (x: x.hook.event) hookList;
in {
  # Claude: settings.json hooks format
  # { "PreToolUse": [{ "matcher": "...", "hooks": [{ "type": "command", "command": "...", "timeout": N }] }] }
  claude = allHooks: timeout: let
    providerHooks = (groupByProvider allHooks).claude or [];
    byEvent = groupByEvent providerHooks;
  in
    lib.mapAttrs (_event: entries: let
      # Group by matcher within each event
      byMatcher = lib.groupBy (x: x.hook.matcher) entries;
    in
      lib.mapAttrsToList (matcher: matcherEntries: {
        inherit matcher;
        hooks =
          map (x: {
            type = "command";
            command = toString x.hook.script;
            inherit timeout;
          })
          matcherEntries;
      })
      byMatcher)
    byEvent;

  # Gemini: settings.json hooks format
  # { "AfterAgent": [{ "hooks": [{ "type": "command", "command": "...", "timeout": N }] }] }
  gemini = allHooks: timeout: let
    providerHooks = (groupByProvider allHooks).gemini or [];
    byEvent = groupByEvent providerHooks;
  in
    lib.mapAttrs (_event: entries: [
      {
        hooks =
          map (x: {
            type = "command";
            command = toString x.hook.script;
            inherit timeout;
          })
          entries;
      }
    ])
    byEvent;

  # Codex: config.toml hooks format
  # { "Stop": [{ "hooks": [{ "type": "command", "command": "...", "timeout": N }] }] }
  codex = allHooks: timeout: let
    providerHooks = (groupByProvider allHooks).codex or [];
    byEvent = groupByEvent providerHooks;
  in
    lib.mapAttrs (_event: entries: [
      {
        hooks =
          map (x: {
            type = "command";
            command = toString x.hook.script;
            inherit timeout;
          })
          entries;
      }
    ])
    byEvent;

  inherit groupByProvider groupByEvent;
}
