#!/usr/bin/env bash
# PreToolUse Guard: Complexity Gate (Computational Sensor)
# Enforces workflow compliance based on complexity classification state.
#
# Rules:
#   - No state file yet → warn (non-blocking), remind to classify
#   - S or M classified → allow all
#   - L classified WITHOUT approval → block Write/Edit (exit 2)
#   - L classified WITH approval → allow all
#
# State files:
#   /tmp/claude-complexity/{session_id}           → "S", "M", or "L"
#   /tmp/claude-complexity/{session_id}.approved   → exists = approved
#
# Exit codes:
#   0 = allow
#   2 = block (L without approval)

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only gate mutation tools
case "$TOOL_NAME" in
  Write|Edit|NotebookEdit) ;;
  *) exit 0 ;;
esac

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)
STATE_DIR="/tmp/claude-complexity"
STATE_FILE="$STATE_DIR/$SESSION_ID"

# No classification yet — soft warning, don't block
if [[ ! -f "$STATE_FILE" ]]; then
  echo "[COMPLEXITY-GATE] No complexity classification found. Run: echo \"S\" > $STATE_FILE (or M or L)"
  exit 0
fi

COMPLEXITY=$(cat "$STATE_FILE" 2>/dev/null | tr -d '[:space:]' | head -c 1)

case "$COMPLEXITY" in
  S|M)
    # S/M: proceed freely
    exit 0
    ;;
  L)
    # L: check for strategy approval
    if [[ -f "${STATE_FILE}.approved" ]]; then
      exit 0
    else
      echo "[COMPLEXITY-GATE] BLOCKED: Task classified as L (complex)."
      echo "Present your strategy to the user first, then after approval run:"
      echo "  touch ${STATE_FILE}.approved"
      exit 2
    fi
    ;;
  *)
    # Unknown classification — warn but allow
    echo "[COMPLEXITY-GATE] Unknown classification '$COMPLEXITY'. Expected S, M, or L."
    exit 0
    ;;
esac
