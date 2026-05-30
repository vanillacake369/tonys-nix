# Mixin (E): Phase State Machine Adapter
# Generates PreToolUse hook scripts that block gated tools
# until phase approval exists for L-complexity tasks.
{
  config,
  lib,
  pkgs,
  ...
}: let
  providers = lib.filterAttrs (_: p: p.enable && p.phases.enforced) config.agentPolicy.providers;

  mkScript = name: prov:
    pkgs.writeShellScript "phase-gate-${name}.sh" ''
      set -euo pipefail
      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | ${lib.getExe' pkgs.jq "jq"} -r '.tool_name // empty' 2>/dev/null)
      SESSION_ID=$(echo "$INPUT" | ${lib.getExe' pkgs.jq "jq"} -r '.session_id // "default"' 2>/dev/null)

      # Only gate configured tools
      case "$TOOL_NAME" in
        ${lib.concatStringsSep "|" prov.phases.gatedTools}) ;;
        *) exit 0 ;;
      esac

      STATE_DIR="${prov.phases.stateDir}"
      STATE_FILE="$STATE_DIR/$SESSION_ID"

      # No classification yet — allow (soft start)
      [[ ! -f "$STATE_FILE" ]] && exit 0

      COMPLEXITY=$(head -c 1 "$STATE_FILE" 2>/dev/null | tr -d '[:space:]')

      case "$COMPLEXITY" in
        S|M) exit 0 ;;
        L)
          if [[ -f "''${STATE_FILE}.approved" ]]; then
            exit 0
          else
            echo "[PHASE-GATE:${name}] BLOCKED: L-complexity without strategy approval."
            echo "Present strategy, then run: touch ''${STATE_FILE}.approved"
            exit 2
          fi
          ;;
        *) exit 0 ;;
      esac
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (providers != {}) {
    phase-gate =
      lib.mapAttrs (name: prov: {
        event = "PreToolUse";
        matcher = lib.concatStringsSep "|" prov.phases.gatedTools;
        script = mkScript name prov;
      })
      providers;
  };
}
