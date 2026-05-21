# Mixin (D): Live Verification Oracle
# Generates PostToolUse hooks that run health checks after mutations.
# Goes beyond lint — executes actual runtime verification commands.
{
  config,
  lib,
  pkgs,
  ...
}: let
  providers = lib.filterAttrs (_: p: p.enable && p.oracle.enabled) config.agentPolicy.providers;

  mkScript = name: prov: let
    checks = prov.oracle.healthChecks;
    checkBlocks =
      lib.concatMapStringsSep "\n" (chk: ''
        # Health check: ${chk.command}
        FILE_PATH=$(echo "$TOOL_INPUT" | $JQ -r '.file_path // empty' 2>/dev/null)
        if [[ -z "$FILE_PATH" ]] || echo "$FILE_PATH" | grep -qE '${chk.pattern}'; then
          if timeout ${toString chk.timeout} ${chk.command} >/dev/null 2>&1; then
            PASSED=$((PASSED + 1))
          else
            FAILED=$((FAILED + 1))
            FAIL_CMDS+=("${chk.command}")
          fi
          TOTAL=$((TOTAL + 1))
        fi
      '')
      checks;
  in
    pkgs.writeShellScript "live-oracle-${name}.sh" ''
      set -uo pipefail
      JQ="${lib.getExe' pkgs.jq "jq"}"

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | $JQ -r '.tool_name // empty' 2>/dev/null)
      TOOL_INPUT=$(echo "$INPUT" | $JQ -r '.tool_input // empty' 2>/dev/null)

      # Only verify after mutation tools
      case "$TOOL_NAME" in
        Write|Edit|NotebookEdit) ;;
        *) exit 0 ;;
      esac

      PASSED=0
      FAILED=0
      TOTAL=0
      FAIL_CMDS=()

      ${checkBlocks}

      if [[ $TOTAL -eq 0 ]]; then
        exit 0
      fi

      if [[ $FAILED -gt 0 ]]; then
        echo "[ORACLE:${name}] $FAILED/$TOTAL health checks FAILED:"
        printf '  - %s\n' "''${FAIL_CMDS[@]}"
        ${lib.optionalString prov.oracle.streamAnalysis ''
        echo "[ORACLE:${name}] Re-running failed checks with output for analysis..."
        for cmd in "''${FAIL_CMDS[@]}"; do
          echo "--- $cmd ---"
          eval "$cmd" 2>&1 | tail -20
          echo "---"
        done
      ''}
        exit 1
      else
        echo "[ORACLE:${name}] All $TOTAL health checks passed."
        exit 0
      fi
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (providers != {}) {
    live-oracle =
      lib.mapAttrs (name: prov: {
        event = "PostToolUse";
        matcher = "Write|Edit|NotebookEdit";
        script = mkScript name prov;
      })
      providers;
  };
}
