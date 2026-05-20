#!/usr/bin/env bash
# Exit-Code Escalation Gate Hook
# Enforces retry-backoff protocol for subagent task execution.
#
# Reads tool_name and tool_input from stdin (Claude Code hook JSON).
# Tracks consecutive failures per tool category and enforces:
#   exit 0 = proceed (success or first attempt)
#   exit 1 = block & retry (Claude auto-adjusts approach)
#   exit 2 = block & escalate (human decision required)
#
# State file: /tmp/claude-escalation-state-$$.json
# Resets on new session (PID-based).

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null)
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty' 2>/dev/null)

# Only gate execution tools (Bash, Write, Edit)
case "$TOOL_NAME" in
  Bash|Write|Edit|NotebookEdit) ;;
  *) exit 0 ;;
esac

# State tracking
STATE_DIR="/tmp/claude-escalation"
mkdir -p "$STATE_DIR"
# Use parent PID (Claude Code process) for session scoping
SESSION_PID=$(ps -o ppid= -p $$ 2>/dev/null | tr -d ' ' || echo "$$")
STATE_FILE="$STATE_DIR/state-${SESSION_PID}.json"

# Initialize state if missing
if [ ! -f "$STATE_FILE" ]; then
  echo '{}' > "$STATE_FILE"
fi

# Detect failure from tool output
IS_FAILURE=false
if echo "$TOOL_OUTPUT" | grep -qiE '(error|fail|exception|panic|FAIL|Error:|fatal)' 2>/dev/null; then
  IS_FAILURE=true
fi

# Extract task key (first 80 chars of tool_input for grouping)
TASK_KEY=$(echo "$TOOL_INPUT" | head -c 80 | tr -d '\n' | sed 's/[^a-zA-Z0-9_-]/_/g')
if [ -z "$TASK_KEY" ]; then
  TASK_KEY="unknown"
fi

# Auto-rollback: stash uncommitted changes on escalation
_auto_rollback() {
  local stash_msg="[ESCALATION-ROLLBACK] $TASK_KEY $(date '+%Y%m%d-%H%M%S')"
  if git -C "$(pwd)" diff --quiet 2>/dev/null && git -C "$(pwd)" diff --cached --quiet 2>/dev/null; then
    echo "[ROLLBACK] No uncommitted changes to stash."
  else
    git -C "$(pwd)" stash push -m "$stash_msg" 2>/dev/null && \
      echo "[ROLLBACK] Changes stashed: $stash_msg" || \
      echo "[ROLLBACK] git stash failed — manual recovery needed."
  fi
}

# Notify: send escalation alert via agent-notify infrastructure
_notify_escalation() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local notify_script="$script_dir/agent-notify.sh"
  if [[ -x "$notify_script" ]]; then
    local json
    json=$(jq -n --arg sid "$SESSION_PID" --arg cwd "$(pwd)" --arg prompt "[ESCALATION] $TASK_KEY" --arg resp "Failed $1 times. Auto-rolled back. Requires human decision." \
      '{session_id: $sid, cwd: $cwd, prompt: $prompt, prompt_response: $resp}')
    echo "$json" | "$notify_script" "escalation" 2>/dev/null || true
  fi
}

if [ "$IS_FAILURE" = "true" ]; then
  # Increment failure count
  CURRENT=$(jq -r --arg k "$TASK_KEY" '.[$k] // 0' "$STATE_FILE" 2>/dev/null || echo "0")
  NEXT=$((CURRENT + 1))
  jq --arg k "$TASK_KEY" --argjson v "$NEXT" '.[$k] = $v' "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null \
    && mv "${STATE_FILE}.tmp" "$STATE_FILE"

  if [ "$NEXT" -ge 3 ]; then
    # 3+ failures: auto-rollback + escalation + notify
    _auto_rollback
    _notify_escalation "$NEXT"
    echo "[ESCALATION] Task failed $NEXT times. Approaches exhausted — requires human decision."
    echo "Task key: $TASK_KEY"
    echo "Failure count: $NEXT"
    echo "Recovery: git stash pop (to restore changes)"
    # Reset counter after escalation
    jq --arg k "$TASK_KEY" '.[$k] = 0' "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null \
      && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    exit 2
  else
    # 1-2 failures: retry with different approach
    echo "[RETRY $NEXT/3] Previous approach failed. Try a different angle — do NOT repeat the same approach."
    exit 1
  fi
else
  # Success: reset counter for this task
  jq --arg k "$TASK_KEY" '.[$k] = 0' "$STATE_FILE" > "${STATE_FILE}.tmp" 2>/dev/null \
    && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  exit 0
fi
