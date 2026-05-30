# Mixin (A): Reasoning Trace Separation
# Generates hooks that manage reasoning visibility based on provider mode.
# - silent:   PostToolUse strips verbose reasoning from output
# - log-only: redirects reasoning to trace log files
# - verbose:  no-op (default pass-through)
{
  config,
  lib,
  pkgs,
  ...
}: let
  providers = lib.filterAttrs (_: p: p.enable && p.reasoning.mode != "verbose") config.agentPolicy.providers;

  mkScript = name: prov:
    pkgs.writeShellScript "reasoning-trace-${name}.sh" ''
      set -uo pipefail
      JQ="${lib.getExe' pkgs.jq "jq"}"

      INPUT=$(cat)
      TOOL_OUTPUT=$(echo "$INPUT" | $JQ -r '.tool_output // empty' 2>/dev/null)
      SESSION_ID=$(echo "$INPUT" | $JQ -r '.session_id // "default"' 2>/dev/null)

      [[ -z "$TOOL_OUTPUT" ]] && exit 0

      TRACE_DIR="${prov.reasoning.traceDir}/${name}"
      mkdir -p "$TRACE_DIR"
      TRACE_FILE="$TRACE_DIR/''${SESSION_ID}.log"

      ${lib.optionalString (prov.reasoning.mode == "log-only") ''
        # Log-only: append full output to trace file with timestamp
        echo "--- $(date -Iseconds) ---" >> "$TRACE_FILE"
        echo "$TOOL_OUTPUT" >> "$TRACE_FILE"
      ''}

      ${lib.optionalString (prov.reasoning.mode == "silent") ''
        # Silent: log reasoning, emit only final decision lines
        echo "--- $(date -Iseconds) ---" >> "$TRACE_FILE"
        echo "$TOOL_OUTPUT" >> "$TRACE_FILE"

        # Extract only lines that look like decisions/actions (heuristic)
        echo "$TOOL_OUTPUT" | grep -E '^\[|^(DECISION|ACTION|RESULT|OUTPUT):' || true
      ''}

      exit 0
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (providers != {}) {
    reasoning-trace =
      lib.mapAttrs (name: prov: {
        event = "PostToolUse";
        matcher = "";
        script = mkScript name prov;
      })
      providers;
  };
}
