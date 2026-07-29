# Mixin (B): Async Sub-Agent Handshake
# Generates FIFO/poll infrastructure for background task communication.
# Providers with async.enabled=true get:
#   - FIFO pipe creation per background task
#   - Handshake completion detection hook
#   - Timeout-based fallback
{
  config,
  lib,
  pkgs,
  ...
}: let
  providers = lib.filterAttrs (_: p: p.enable && p.async.enabled) config.agentPolicy.providers;

  mkFifoSetup = name: prov:
    pkgs.writeShellScript "async-setup-${name}.sh" ''
      set -euo pipefail
      FIFO_DIR="${prov.async.fifoDir}/${name}"
      mkdir -p "$FIFO_DIR"

      # Create named pipes for each background task
      ${lib.concatMapStringsSep "\n" (task: ''
          PIPE="$FIFO_DIR/${task}.fifo"
          [[ -p "$PIPE" ]] || mkfifo "$PIPE"
        '')
        prov.async.backgroundTasks}

      echo "[ASYNC-SETUP:${name}] FIFO pipes ready in $FIFO_DIR"
    '';

  mkHandshakeScript = name: prov:
    pkgs.writeShellScript "async-handshake-${name}.sh" ''
      set -uo pipefail
      JQ="${lib.getExe' pkgs.jq "jq"}"

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | $JQ -r '.tool_name // empty' 2>/dev/null)
      SESSION_ID=$(echo "$INPUT" | $JQ -r '.session_id // "default"' 2>/dev/null)

      # Only activate for Agent tool completions
      [[ "$TOOL_NAME" != "Agent" ]] && exit 0

      FIFO_DIR="''${AGENT_ASYNC_FIFO_DIR:-${prov.async.fifoDir}}/${name}"
      RESULT_DIR="$FIFO_DIR/results"
      mkdir -p "$RESULT_DIR"

      TOOL_OUTPUT=$(echo "$INPUT" | $JQ -r '
        .tool_output
        // .tool_response.output
        // .tool_response.aggregated_output
        // .tool_result.output
        // .tool_result.aggregated_output
        // .item.aggregated_output
        // .aggregated_output
        // .output
        // (
          if ((.tool_response.stdout? // null) != null or (.tool_response.stderr? // null) != null)
          then ((.tool_response.stdout // "") + "\n" + (.tool_response.stderr // ""))
          else empty
          end
        )
        // empty
      ' 2>/dev/null)

      # Write result to completion file (non-blocking alternative to FIFO)
      RESULT_FILE="$RESULT_DIR/''${SESSION_ID}-$(date +%s).json"
      echo "$INPUT" | $JQ --arg output "$TOOL_OUTPUT" '{
        session_id: .session_id,
        tool_name: .tool_name,
        completed_at: now | todate,
        output_length: ($output | length)
      }' > "$RESULT_FILE" 2>/dev/null || true

      echo "[ASYNC-HANDSHAKE:${name}] Task result captured: $RESULT_FILE"
      exit 0
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (providers != {}) {
    async-handshake =
      lib.mapAttrs (name: prov: {
        event = "PostToolUse";
        matcher = "Agent";
        script = mkHandshakeScript name prov;
      })
      providers;
  };

  # Activation script: ensure FIFO infrastructure exists
  config.home.activation = lib.mkIf (providers != {}) (
    lib.mapAttrs' (name: prov:
      lib.nameValuePair "asyncSetup-${name}" (
        lib.hm.dag.entryAfter ["writeBoundary"] ''
          run ${mkFifoSetup name prov}
        ''
      ))
    providers
  );
}
