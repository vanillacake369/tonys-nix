# Mixin (F): Strategy Linter / LSP Hook Gate
# Validates strategy documents contain required sections before allowing execution.
# Optionally triggers peer review via another provider.
{
  config,
  lib,
  pkgs,
  ...
}: let
  providers = lib.filterAttrs (_: p: p.enable && p.strategyLint.enabled) config.agentPolicy.providers;
  stateRoot = config.agentPolicy.global.stateRoot;

  mkScript = name: prov: let
    sections = prov.strategyLint.requiredSections;
    sectionChecks =
      lib.concatMapStringsSep "\n" (s: ''
        if ! grep -qi "${s}" "$STRATEGY_FILE" 2>/dev/null; then
          MISSING+=("${s}")
        fi
      '')
      sections;
    reviewer = prov.strategyLint.peerReviewProvider;
  in
    pkgs.writeShellScript "strategy-lint-${name}.sh" ''
      set -euo pipefail
      JQ="${lib.getExe' pkgs.jq "jq"}"

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | $JQ -r '.tool_name // empty' 2>/dev/null)
      SESSION_ID=$(echo "$INPUT" | $JQ -r '.session_id // "default"' 2>/dev/null)

      # Only gate mutation tools
      case "$TOOL_NAME" in
        Write|Edit|NotebookEdit) ;;
        *) exit 0 ;;
      esac

      STRATEGY_DIR="${prov.strategyLint.strategyPath}"
      STRATEGY_FILE="$STRATEGY_DIR/$SESSION_ID.md"
      REVIEW_FILE="$STRATEGY_DIR/''${SESSION_ID}-review.md"

      # No strategy file yet — allow (first-time pass)
      [[ ! -f "$STRATEGY_FILE" ]] && exit 0

      # Check required sections
      MISSING=()
      ${sectionChecks}

      if [[ ''${#MISSING[@]} -gt 0 ]]; then
        echo "[STRATEGY-LINT:${name}] Missing required sections: ''${MISSING[*]}"
        echo "Add these sections to $STRATEGY_FILE before proceeding."
        exit 2
      fi

      ${lib.optionalString (reviewer != null) ''
        # Peer review gate: require review file to exist
        if [[ ! -f "$REVIEW_FILE" ]]; then
          echo "[STRATEGY-LINT:${name}] Peer review from '${reviewer}' not found."
          echo "Expected: $REVIEW_FILE"
          echo "Run peer review before proceeding to execution."
          exit 2
        fi
      ''}

      exit 0
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (providers != {}) {
    strategy-lint =
      lib.mapAttrs (name: prov: {
        event = "PreToolUse";
        matcher = "Write|Edit|NotebookEdit";
        script = mkScript name prov;
      })
      providers;
  };
}
