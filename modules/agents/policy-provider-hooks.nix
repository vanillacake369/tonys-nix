# Base hooks SSoT — provider-specific manually-defined hooks + shared merge logic.
# Claude's base hooks live in dotfiles/claude/settings.json (full settings file);
# Gemini and Codex base hooks are defined here as the single source of truth.
{lib}: {
  gemini = {
    AfterAgent = [
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

  codex = {
    Stop = [
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
  };

  # Shared merge logic: base hooks ++ policy-generated hooks per event
  mergeHooks = baseHooks: policyHooks: let
    events = lib.unique (lib.attrNames baseHooks ++ lib.attrNames policyHooks);
  in
    lib.genAttrs events (event:
      (baseHooks.${event} or []) ++ (policyHooks.${event} or []));
}
