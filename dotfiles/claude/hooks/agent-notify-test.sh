#!/usr/bin/env bash
# Tests for agent-notify.sh
# Usage: bash agent-notify-test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY_SCRIPT="$SCRIPT_DIR/agent-notify.sh"

PASS=0
FAIL=0
TOTAL=0

# ===========================================================================
# Test helpers
# ===========================================================================

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected to contain: '$needle'"
    echo "    actual:              '$haystack'"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected NOT to contain: '$needle'"
    echo "    actual:                  '$haystack'"
    FAIL=$((FAIL + 1))
  fi
}

# ===========================================================================
# 1. Input Parsing
# ===========================================================================

echo "=== 1. Input Parsing ==="

# 1-1. Claude Code Stop hook JSON (no prompt field)
result=$(echo '{"session_id":"abc-123","cwd":"/home/user/project","transcript_path":"/tmp/t.jsonl"}' \
  | bash "$NOTIFY_SCRIPT" --parse-test claude)
assert_contains "claude: extracts session_id" "session_id=abc-123" "$result"
assert_contains "claude: extracts cwd" "cwd=/home/user/project" "$result"
assert_contains "claude: provider is claude" "provider=claude" "$result"
assert_contains "claude: prompt is empty when missing" "prompt=" "$result"

# 1-2. Codex Stop hook JSON (has last_assistant_message)
result=$(echo '{"session_id":"codex-456","cwd":"/workspace","last_assistant_message":"Fixed the auth bug"}' \
  | bash "$NOTIFY_SCRIPT" --parse-test codex)
assert_contains "codex: extracts session_id" "codex-456" "$result"
assert_contains "codex: extracts last_assistant_message as summary" "summary=Fixed the auth bug" "$result"

# 1-3. Gemini AfterAgent hook JSON (has prompt + prompt_response)
result=$(echo '{"session_id":"gem-789","cwd":"/dev/app","prompt":"Add unit tests for auth module","prompt_response":"Done. Created 5 test cases."}' \
  | bash "$NOTIFY_SCRIPT" --parse-test gemini)
assert_contains "gemini: extracts prompt" "prompt=Add unit tests for auth module" "$result"
assert_contains "gemini: extracts summary from prompt_response" "summary=Done. Created 5 test cases." "$result"

# 1-4. Missing session_id falls back to "unknown"
result=$(echo '{"cwd":"/tmp"}' \
  | bash "$NOTIFY_SCRIPT" --parse-test claude)
assert_contains "missing session_id: falls back to unknown" "session_id=unknown" "$result"

# 1-5. Missing cwd falls back to "unknown"
result=$(echo '{"session_id":"x"}' \
  | bash "$NOTIFY_SCRIPT" --parse-test claude)
assert_contains "missing cwd: falls back to unknown" "cwd=unknown" "$result"

# 1-6. Empty stdin
result=$(echo '' | bash "$NOTIFY_SCRIPT" --parse-test claude)
assert_contains "empty stdin: session_id=unknown" "session_id=unknown" "$result"
assert_contains "empty stdin: cwd=unknown" "cwd=unknown" "$result"

# 1-7. Invalid JSON
result=$(echo 'not-json' | bash "$NOTIFY_SCRIPT" --parse-test claude)
assert_contains "invalid json: session_id=unknown" "session_id=unknown" "$result"

echo ""

# ===========================================================================
# 2. Notification Args (terminal-notifier params)
# ===========================================================================

echo "=== 2. Notification Args ==="

# 2-1. Claude: title, subtitle (project), group, message (no prompt → session info)
result=$(echo '{"session_id":"abc-123","cwd":"/home/user/my-project"}' \
  | bash "$NOTIFY_SCRIPT" --notify-args-test claude)
assert_contains "claude title" "title=Claude" "$result"
assert_contains "claude subtitle is project dir" "subtitle=my-project" "$result"
assert_contains "claude group has provider+session" "group=claude-abc-123" "$result"
assert_contains "claude message shows completed" "completed" "$result"

# 2-2. Gemini: prompt shown as message
result=$(echo '{"session_id":"gem-1","cwd":"/dev/app","prompt":"Add retry logic to API calls"}' \
  | bash "$NOTIFY_SCRIPT" --notify-args-test gemini)
assert_contains "gemini title" "title=Gemini" "$result"
assert_contains "gemini message includes prompt" "Add retry logic" "$result"

# 2-3. Codex: last_assistant_message shown as message
result=$(echo '{"session_id":"cdx-1","cwd":"/workspace","last_assistant_message":"Refactored auth module into 3 files"}' \
  | bash "$NOTIFY_SCRIPT" --notify-args-test codex)
assert_contains "codex title" "title=Codex" "$result"
assert_contains "codex message includes summary" "Refactored auth" "$result"

# 2-4. Long prompt gets truncated
long_prompt="Implement comprehensive error handling for all API endpoints including retry logic and circuit breaker pattern with exponential backoff"
result=$(echo "{\"session_id\":\"x\",\"cwd\":\"/tmp\",\"prompt\":\"$long_prompt\"}" \
  | bash "$NOTIFY_SCRIPT" --notify-args-test gemini)
# Message should be truncated (max 60 chars for readability)
msg_line=$(echo "$result" | grep '^message=')
msg_len=${#msg_line}
# "message=" is 8 chars, so content should be <= 68
if [[ $msg_len -le 72 ]]; then
  echo "  PASS: long prompt is truncated"
  PASS=$((PASS + 1))
else
  echo "  FAIL: long prompt is truncated (len=$msg_len)"
  FAIL=$((FAIL + 1))
fi
TOTAL=$((TOTAL + 1))

# 2-5. execute calls agent-notify-open.sh with session name when ZELLIJ_SESSION_NAME is set
if [[ "$(uname)" == "Darwin" ]]; then
  result=$(echo '{"session_id":"x","cwd":"/tmp"}' \
    | ZELLIJ_SESSION_NAME=my-session bash "$NOTIFY_SCRIPT" --notify-args-test claude)
  assert_contains "execute calls open script" "agent-notify-open.sh" "$result"
  assert_contains "execute passes session name" "my-session" "$result"
fi

# 2-6. execute without zellij calls open script without session arg
if [[ "$(uname)" == "Darwin" ]]; then
  result=$(echo '{"session_id":"x","cwd":"/tmp"}' \
    | ZELLIJ_SESSION_NAME= bash "$NOTIFY_SCRIPT" --notify-args-test claude)
  assert_contains "execute without zellij: calls open script" "agent-notify-open.sh" "$result"
  assert_not_contains "execute without zellij: no session arg" "agent-notify-open.sh " "$result"
fi

# 2-7. No provider defaults to Agent
result=$(echo '{"session_id":"x","cwd":"/tmp"}' \
  | bash "$NOTIFY_SCRIPT" --notify-args-test)
assert_contains "default title is Agent" "title=Agent" "$result"

echo ""

# ===========================================================================
# 3. Backend Selection
# ===========================================================================

echo "=== 3. Backend Selection ==="

result=$(AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT" --backend-test)
assert_contains "dry run: returns a backend name" "backend=" "$result"

result=$(AGENT_NOTIFY_BACKEND=bell AGENT_NOTIFY_DRY_RUN=1 \
  bash "$NOTIFY_SCRIPT" --backend-test)
assert_eq "forced bell backend" "backend=bell" "$result"

result=$(AGENT_NOTIFY_BACKEND=noti AGENT_NOTIFY_DRY_RUN=1 \
  bash "$NOTIFY_SCRIPT" --backend-test)
assert_eq "forced noti backend" "backend=noti" "$result"

result=$(AGENT_NOTIFY_BACKEND=osascript AGENT_NOTIFY_DRY_RUN=1 \
  bash "$NOTIFY_SCRIPT" --backend-test)
assert_eq "forced osascript backend" "backend=osascript" "$result"

result=$(AGENT_NOTIFY_BACKEND=terminal-notifier AGENT_NOTIFY_DRY_RUN=1 \
  bash "$NOTIFY_SCRIPT" --backend-test)
assert_eq "forced terminal-notifier backend" "backend=terminal-notifier" "$result"

echo ""

# ===========================================================================
# 4. Integration (dry-run, full pipeline)
# ===========================================================================

echo "=== 4. Integration (dry-run) ==="

# 4-1. Claude full flow
result=$(echo '{"session_id":"int-001","cwd":"/home/user/my-project"}' \
  | AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT" claude)
assert_contains "integration claude: title" "title=Claude" "$result"
assert_contains "integration claude: subtitle" "subtitle=my-project" "$result"
assert_contains "integration claude: group" "group=claude-int-001" "$result"
assert_contains "integration claude: backend" "backend=" "$result"

# 4-2. Gemini with prompt
result=$(echo '{"session_id":"int-002","cwd":"/dev/frontend","prompt":"Fix CSS layout bug"}' \
  | AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT" gemini)
assert_contains "integration gemini: title" "title=Gemini" "$result"
assert_contains "integration gemini: prompt in message" "Fix CSS layout bug" "$result"

# 4-3. Codex with last_assistant_message
result=$(echo '{"session_id":"int-003","cwd":"/workspace/api","last_assistant_message":"Added 3 endpoints"}' \
  | AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT" codex)
assert_contains "integration codex: title" "title=Codex" "$result"
assert_contains "integration codex: summary in message" "Added 3 endpoints" "$result"

# 4-4. No provider
result=$(echo '{"session_id":"no-prov","cwd":"/tmp/test"}' \
  | AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT")
assert_contains "no provider: defaults to Agent" "title=Agent" "$result"

echo ""

# ===========================================================================
# 5. Focus Suppression
# ===========================================================================

echo "=== 5. Focus Suppression ==="

# 5-1. Skips when session has clients (user is viewing this session)
result=$(echo '{"session_id":"x","cwd":"/tmp"}' \
  | AGENT_NOTIFY_DRY_RUN=1 _TEST_CLIENT_COUNT=1 bash "$NOTIFY_SCRIPT" claude)
assert_contains "has clients: skipped" "skipped" "$result"

# 5-2. Sends when session has no clients (user is in different session)
result=$(echo '{"session_id":"x","cwd":"/tmp"}' \
  | AGENT_NOTIFY_DRY_RUN=1 _TEST_CLIENT_COUNT=0 bash "$NOTIFY_SCRIPT" claude)
assert_not_contains "no clients: not skipped" "skipped" "$result"
assert_contains "no clients: has title" "title=" "$result"

# 5-3. Sends when not in zellij (no ZELLIJ_SESSION_NAME)
result=$(echo '{"session_id":"x","cwd":"/tmp"}' \
  | AGENT_NOTIFY_DRY_RUN=1 ZELLIJ_SESSION_NAME= _TEST_CLIENT_COUNT= bash "$NOTIFY_SCRIPT" claude)
assert_not_contains "no zellij: not skipped" "skipped" "$result"

echo ""

# ===========================================================================
# 6. Exit Code
# ===========================================================================

echo "=== 6. Exit Code ==="

echo '{}' | AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT" claude >/dev/null
assert_eq "exit code is 0" "0" "$?"

echo '{"bad json' | AGENT_NOTIFY_DRY_RUN=1 bash "$NOTIFY_SCRIPT" claude 2>/dev/null >/dev/null
assert_eq "exit code is 0 even with bad json" "0" "$?"

echo ""

# ===========================================================================
# Summary
# ===========================================================================

echo "==========================================="
echo "Results: $PASS passed, $FAIL failed, $TOTAL total"
echo "==========================================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
