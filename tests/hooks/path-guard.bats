#!/usr/bin/env bats
# path-guard generated hook: structured paths and Bash sensitive-read blocking.

setup() {
  WORK=$(mktemp -d)
  export AGENTOPS_EVENT_LOG="$WORK/events.jsonl"
  export AGENTOPS_OTLP_ENDPOINT="http://127.0.0.1:9/v1/traces"
  if [[ -z "${PATH_GUARD_HOOK:-}" ]]; then
    skip "PATH_GUARD_HOOK is only available in the generated hook flake check"
  fi
}

teardown() { rm -rf "$WORK"; }

mkfile() {
  local tool="${1:-Read}"
  local path="${2:-$WORK/.env}"
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s"},"session_id":"s-path","workflow_id":"code-implementation","slice_id":"slice-a"}' "$tool" "$path"
}

mkbash() {
  local command="$1"
  local cwd="${2:-}"
  if [[ -n "$cwd" ]]; then
    printf '{"tool_name":"Bash","tool_input":{"command":"%s","cwd":"%s"},"session_id":"s-bash","workflow_id":"code-implementation","slice_id":"slice-a"}' "$command" "$cwd"
  else
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"session_id":"s-bash","workflow_id":"code-implementation","slice_id":"slice-a"}' "$command"
  fi
}

run_guard() {
  printf '%s' "$1" > "$WORK/input.json"
  run bash "$PATH_GUARD_HOOK" <"$WORK/input.json"
}

last_event_field() {
  tail -1 "$AGENTOPS_EVENT_LOG" | jq -r ".$1"
}

assert_agentops_event_contract() {
  jq -e '
    .schemaVersion == "agentops.event.v1" and
    (.event_id | type == "string" and length > 0) and
    (.run_id | type == "string" and length > 0) and
    (.timestamp | type == "string" and length > 0) and
    (.event_type | type == "string" and length > 0) and
    (.provider | type == "string" and length > 0) and
    .content_capture == false and
    (.operation_id | type == "string" and length > 0) and
    (.risk_level | type == "string" and length > 0) and
    (.approval_required | type == "boolean") and
    (.sandbox_mode | type == "string" and length > 0) and
    (.policy_source | type == "string" and length > 0)
  ' "$AGENTOPS_EVENT_LOG" >/dev/null
}

@test "structured Read blocks sensitive file and emits schema fields" {
  run_guard "$(mkfile Read "$WORK/.env")"
  [ "$status" -eq 2 ]
  assert_agentops_event_contract
  [[ "$output" != *".env"* ]]
  [ "$(last_event_field schemaVersion)" = "agentops.event.v1" ]
  [ "$(last_event_field event_type)" = "agentops.security_intercept" ]
  [ "$(last_event_field content_capture)" = "false" ]
  [ "$(last_event_field risk_level)" = "unknown" ]
  [ "$(last_event_field approval_required)" = "false" ]
  [ "$(last_event_field policy_source)" = "agentPolicy.global.sensitivePatterns" ]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path" ]
}

@test "Bash cat blocks sensitive file read" {
  run_guard "$(mkbash "cat $WORK/.env")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"sensitive Bash read"* ]]
  [[ "$output" != *".env"* ]]
  [ "$(last_event_field tool_name)" = "Bash" ]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash grep blocks sensitive directory read" {
  mkdir -p "$WORK/secrets"
  run_guard "$(mkbash "grep token $WORK/secrets/prod.env")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash quoted sensitive path is normalized before matching" {
  run_guard "$(mkbash "sed -n '1p' '$WORK/.env.local'")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash rg search pattern named token is not treated as a path" {
  run_guard "$(mkbash "rg token modules")"
  [ "$status" -eq 0 ]
  [ ! -f "$AGENTOPS_EVENT_LOG" ]
}

@test "Bash grep search pattern named token is not treated as a path" {
  run_guard "$(mkbash "grep token README.md")"
  [ "$status" -eq 0 ]
  [ ! -f "$AGENTOPS_EVENT_LOG" ]
}

@test "Bash blocks pem reads without leaking sensitive filename" {
  run_guard "$(mkbash "cat $WORK/private.pem")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"private.pem"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
  [ "$(last_event_field artifact_path)" = "[redacted]" ]
}

@test "Bash blocks service account reads without leaking sensitive filename" {
  run_guard "$(mkbash "cat $WORK/service-account-prod.json")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"service-account-prod.json"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash blocks bare sensitive basename without relying on hook cwd" {
  run_guard "$(mkbash "cat id_rsa" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"id_rsa"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash grep -f treats following token as sensitive file operand" {
  run_guard "$(mkbash "grep -f id_rsa /dev/null" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"id_rsa"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash rg -f treats following token as sensitive file operand" {
  run_guard "$(mkbash "rg -f token ." "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"token"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash sed -f treats following token as sensitive file operand" {
  run_guard "$(mkbash "sed -f credentials /dev/null" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"credentials"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash awk -f treats following token as sensitive file operand" {
  run_guard "$(mkbash "awk -f credentials input" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"credentials"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash sed attached -f operand is blocked" {
  run_guard "$(mkbash "sed -fcredentials /dev/null" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"credentials"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash awk attached -f operand is blocked" {
  run_guard "$(mkbash "awk -fcredentials input" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"credentials"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash grep --file attached operand is blocked" {
  run_guard "$(mkbash "grep --file=id_rsa /dev/null" "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"id_rsa"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash rg --file attached operand is blocked" {
  run_guard "$(mkbash "rg --file=token ." "$WORK")"
  [ "$status" -eq 2 ]
  [[ "$output" != *"token"* ]]
  [ "$(last_event_field failure_taxonomy)" = "sensitive-path-read" ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "Bash echo does not block sensitive-looking text" {
  run_guard "$(mkbash "echo .env")"
  [ "$status" -eq 0 ]
  [ ! -f "$AGENTOPS_EVENT_LOG" ]
}
