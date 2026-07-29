#!/usr/bin/env bats
# Generated PostToolUse hooks must handle provider payload variants.

setup() {
  WORK=$(mktemp -d)
  export AGENT_TRACE_DIR="$WORK/traces"
  export AGENT_ASYNC_FIFO_DIR="$WORK/async"
}

teardown() { rm -rf "$WORK"; }

@test "reasoning-trace reads tool_response output" {
  [[ -n "${REASONING_TRACE_HOOK:-}" ]] || skip "generated reasoning trace hook path is only available in the flake check"

  payload='{
    "tool_name":"Bash",
    "session_id":"s-reason",
    "tool_response":{"output":"RESULT: generated hook output\ninternal detail"}
  }'

  run bash "$REASONING_TRACE_HOOK" <<<"$payload"

  [ "$status" -eq 0 ]
  [[ "$output" == *"RESULT: generated hook output"* ]]
  grep -q "internal detail" "$AGENT_TRACE_DIR/claude/s-reason.log"
}

@test "codex reasoning-trace reads aggregated Bash output" {
  [[ -n "${CODEX_REASONING_TRACE_HOOK:-}" ]] || skip "generated Codex reasoning trace hook path is only available in the flake check"

  payload='{
    "tool_name":"Bash",
    "session_id":"s-codex",
    "tool_response":{"aggregated_output":"CODEX RESULT: generated hook output\ncodex detail"}
  }'

  run bash "$CODEX_REASONING_TRACE_HOOK" <<<"$payload"

  [ "$status" -eq 0 ]
  grep -q "codex detail" "$AGENT_TRACE_DIR/codex/s-codex.log"
}

@test "async-handshake records tool_response output length" {
  [[ -n "${ASYNC_HANDSHAKE_HOOK:-}" ]] || skip "generated async handshake hook path is only available in the flake check"

  payload='{
    "tool_name":"Agent",
    "session_id":"s-async",
    "tool_response":{"stdout":"review complete","stderr":""}
  }'

  run bash "$ASYNC_HANDSHAKE_HOOK" <<<"$payload"

  [ "$status" -eq 0 ]
  result_file="$(find "$AGENT_ASYNC_FIFO_DIR/gemini/results" -type f -name 's-async-*.json' | head -1)"
  [ -n "$result_file" ]
  [ "$(jq -r '.output_length' "$result_file")" -gt 0 ]
}
