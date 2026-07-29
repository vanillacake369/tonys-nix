#!/usr/bin/env bats
# agentops-workflow-gate generated hooks: production phase entry rules,
# mutation gate, verify repair transition, commit evidence, schema, redaction.

setup() {
  WORK=$(mktemp -d)
  export AGENTOPS_WORKFLOW_STATE_DIR="$WORK/state"
  export AGENTOPS_EVENT_LOG="$WORK/events.jsonl"
  export AGENTOPS_OTLP_ENDPOINT="http://127.0.0.1:9/v1/traces"
  export AGENTOPS_MARKER_SECRET="test-secret"
  export AGENTOPS_CONTEXT_LOADED="shared-agent-guide,agent-policy-modules"
  mkdir -p "$AGENTOPS_WORKFLOW_STATE_DIR"
  : "${PRE_HOOK:?PRE_HOOK must point to generated PreToolUse hook}"
  : "${POST_HOOK:?POST_HOOK must point to generated PostToolUse hook}"
}

teardown() { rm -rf "$WORK"; }

mkinput() {
  local tool="${1:-Edit}"
  local session="${2:-s1}"
  local command="${3:-}"
  if [[ "$tool" == "Bash" ]]; then
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"session_id":"%s","workflow_id":"code-implementation","slice_id":"slice-a"}' "$command" "$session"
  else
    printf '{"tool_name":"%s","tool_input":{"file_path":"%s/file.nix"},"session_id":"%s","workflow_id":"code-implementation","slice_id":"slice-a"}' "$tool" "$WORK" "$session"
  fi
}

mkinput_with_context() {
  local session="${1:-s-context}"
  local context_json="${2:-[]}"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/file.nix"},"session_id":"%s","workflow_id":"code-implementation","slice_id":"slice-a","metadata":{"context_loaded":%s}}' "$WORK" "$session" "$context_json"
}

mkpost() {
  local session="${1:-s1}"
  local command="${2:-nix flake check --no-build}"
  local code="${3:-0}"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"tool_exit_code":%s,"session_id":"%s","workflow_id":"code-implementation","slice_id":"slice-a"}' "$command" "$code" "$session"
}

set_phase() {
  local session="${1:-s1}"
  local phase="${2:-impl}"
  printf '%s' "$phase" > "$AGENTOPS_WORKFLOW_STATE_DIR/$session.phase"
}

mark() {
  local session="$1"
  local phase="$2"
  local result="$3"
  local source="${4:-agentops-policy}"
  jq -cn \
    --arg session "$session" \
    --arg phase "$phase" \
    --arg result "$result" \
    --arg source "$source" \
    '{schema_version:"agentops.marker.v1",timestamp:"2026-07-06T00:00:00Z",session_id:$session,phase:$phase,result:$result,source:$source,command_hash:"",reason:""}' \
    > "$AGENTOPS_WORKFLOW_STATE_DIR/$session.$phase.$result.json"
}

hook_mark() {
  local session="$1"
  local phase="$2"
  local result="$3"
  local command="${4:-nix flake check --no-build}"
  local reason="${5:-}"
  local hash signature
  hash="$(printf '%s' "$command" | sha256sum | awk '{print $1}')"
  signature="$(printf '%s' "$AGENTOPS_MARKER_SECRET|$session|$phase|$result|agentops-hook|$hash|$reason" | sha256sum | awk '{print $1}')"
  jq -cn \
    --arg session "$session" \
    --arg phase "$phase" \
    --arg result "$result" \
    --arg hash "$hash" \
    --arg reason "$reason" \
    --arg signature "$signature" \
    '{schema_version:"agentops.marker.v1",timestamp:"2026-07-06T00:00:00Z",session_id:$session,phase:$phase,result:$result,source:"agentops-hook",command_hash:$hash,reason:$reason,signature:$signature}' \
    > "$AGENTOPS_WORKFLOW_STATE_DIR/$session.$phase.$result.json"
}

run_pre() {
  printf '%s' "$1" > "$WORK/input.json"
  run bash "$PRE_HOOK" <"$WORK/input.json"
}

run_post() {
  printf '%s' "$1" > "$WORK/input.json"
  run bash "$POST_HOOK" <"$WORK/input.json"
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

@test "missing phase blocks mutation and emits AgentOpsEvent schema" {
  run_pre "$(mkinput Edit s-missing)"
  [ "$status" -eq 2 ]
  assert_agentops_event_contract
  [ "$(last_event_field schemaVersion)" = "agentops.event.v1" ]
  [ "$(last_event_field schema_version)" = "agentops.event.v1" ]
  [ "$(last_event_field event_type)" = "agentops.workflow_gate" ]
  [ "$(last_event_field content_capture)" = "false" ]
  [ "$(last_event_field risk_level)" = "medium" ]
  [ "$(last_event_field approval_required)" = "false" ]
  [ "$(last_event_field policy_source)" = "agentPolicy.workflow.phase-gate" ]
  [ "$(last_event_field decision)" = "block" ]
  [ "$(last_event_field result)" = "fail" ]
  [ "$(last_event_field failure_taxonomy)" = "missing-phase" ]
  [ "$(last_event_field failure_class)" = "missing-context" ]
  [ "$(last_event_field retry_count)" = "0" ]
}

@test "post hook ignores non-verify bash payload without active phase" {
  run_post "$(mkpost s-no-phase "echo done" 0)"
  [ "$status" -eq 0 ]
}

@test "guardrail-verify requires guardrail-create done marker" {
  set_phase s-entry guardrail-verify
  run_pre "$(mkinput Bash s-entry "nix flake check --no-build")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "entry-evidence-missing" ]
  [ "$(last_event_field approval_required)" = "true" ]
  [ "$(last_event_field approval_granted)" = "false" ]
}

@test "guardrail-verify accepts valid provenance marker" {
  set_phase s-entry-ok guardrail-verify
  mark s-entry-ok guardrail-create done
  run_pre "$(mkinput Bash s-entry-ok "nix flake check --no-build")"
  [ "$status" -eq 0 ]
}

@test "signed hook marker is accepted as entry evidence" {
  set_phase s-signed review
  hook_mark s-signed verify pass
  run_pre "$(mkinput Bash s-signed "true")"
  [ "$status" -eq 0 ]
}

@test "marker with invalid source is rejected" {
  set_phase s-fake impl
  mark s-fake guardrail-verify pass manual
  run_pre "$(mkinput Edit s-fake)"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "entry-evidence-missing" ]
}

@test "hook marker with invalid signature is rejected" {
  set_phase s-badsig review
  hook_mark s-badsig verify pass
  jq '.signature = "bad"' "$AGENTOPS_WORKFLOW_STATE_DIR/s-badsig.verify.pass.json" > "$WORK/bad.json"
  mv "$WORK/bad.json" "$AGENTOPS_WORKFLOW_STATE_DIR/s-badsig.verify.pass.json"
  run_pre "$(mkinput Bash s-badsig "true")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "entry-evidence-missing" ]
}

@test "verify phase blocks Write/Edit mutation" {
  set_phase s-verify verify
  mark s-verify impl done
  run_pre "$(mkinput Edit s-verify)"
  [ "$status" -eq 2 ]
  [[ "$output" == *"mutation tool"* ]]
  [ "$(last_event_field failure_taxonomy)" = "mutation-outside-phase" ]
  [ "$(last_event_field failure_class)" = "wrong-tool" ]
  [ "$(last_event_field approval_required)" = "true" ]
  [ "$(last_event_field approval_granted)" = "false" ]
}

@test "verify phase blocks bash redirection mutation" {
  set_phase s-redirect verify
  mark s-redirect impl done
  run_pre "$(mkinput Bash s-redirect "printf x > file.nix")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "mutation-outside-phase" ]
}

@test "verify phase blocks bash redirection with quoted target" {
  set_phase s-redirect-quoted verify
  mark s-redirect-quoted impl done
  run_pre "$(mkinput Bash s-redirect-quoted "printf x > \\\"file.nix\\\"")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "mutation-outside-phase" ]
}

@test "verify phase allows read-only command with stderr discarded" {
  set_phase s-stderr-null verify
  mark s-stderr-null impl done
  run_pre "$(mkinput Bash s-stderr-null "find . -maxdepth 1 -type f 2>/dev/null")"
  [ "$status" -eq 0 ]
}

@test "verify phase allows read-only grep pattern containing redirect characters" {
  set_phase s-grep-pattern verify
  mark s-grep-pattern impl done
  run_pre "$(mkinput Bash s-grep-pattern "rg -n '(^|[^<])>>?[[:space:]]*[^&[:space:]]' modules")"
  [ "$status" -eq 0 ]
}

@test "verify phase blocks bash tee mutation" {
  set_phase s-tee verify
  mark s-tee impl done
  run_pre "$(mkinput Bash s-tee "printf x | tee file.nix")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "mutation-outside-phase" ]
}

@test "verify phase blocks external apply mutation" {
  set_phase s-kubectl verify
  mark s-kubectl impl done
  run_pre "$(mkinput Bash s-kubectl "kubectl apply -f deploy.yaml")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "mutation-outside-phase" ]
}

@test "impl phase requires guardrail verification and then allows mutation" {
  set_phase s-impl impl
  mark s-impl guardrail-verify pass
  run_pre "$(mkinput Edit s-impl)"
  [ "$status" -eq 0 ]
  [ "$(last_event_field decision)" = "allow" ]
}

@test "verify pass creates marker and advances to review" {
  set_phase s-vpass verify
  mark s-vpass impl done
  run_post "$(mkpost s-vpass "nix flake check --no-build" 0)"
  [ "$status" -eq 0 ]
  [ "$(cat "$AGENTOPS_WORKFLOW_STATE_DIR/s-vpass.phase")" = "review" ]
  jq -e '.source == "agentops-hook" and .phase == "verify" and .result == "pass"' "$AGENTOPS_WORKFLOW_STATE_DIR/s-vpass.verify.pass.json"
  jq -e '.command_hash | test("^[0-9a-f]{64}$")' "$AGENTOPS_WORKFLOW_STATE_DIR/s-vpass.verify.pass.json"
  jq -e '.signature | test("^[0-9a-f]{64}$")' "$AGENTOPS_WORKFLOW_STATE_DIR/s-vpass.verify.pass.json"
  [ "$(last_event_field result)" = "pass" ]
}

@test "verify fail creates marker and advances to repair-on-verify-fail" {
  set_phase s-vfail verify
  mark s-vfail impl done
  run_post "$(mkpost s-vfail "nix flake check --no-build" 1)"
  [ "$status" -eq 0 ]
  [ "$(cat "$AGENTOPS_WORKFLOW_STATE_DIR/s-vfail.phase")" = "repair-on-verify-fail" ]
  jq -e '.source == "agentops-hook" and .phase == "verify" and .result == "fail"' "$AGENTOPS_WORKFLOW_STATE_DIR/s-vfail.verify.fail.json"
  [ "$(last_event_field failure_taxonomy)" = "verify-failed" ]
  [ "$(last_event_field failure_class)" = "verification-failure" ]
}

@test "review cannot start after verify failure" {
  set_phase s-review review
  mark s-review verify fail
  run_pre "$(mkinput Bash s-review "true")"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "entry-evidence-missing" ]
}

@test "git commit before future research evidence is blocked" {
  set_phase s-commit commit
  mark s-commit verify pass
  mark s-commit review pass
  mark s-commit postmortem done
  run_pre "$(mkinput Bash s-commit "git commit -m test")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"future-research"* ]]
  [ "$(last_event_field failure_taxonomy)" = "entry-evidence-missing" ]
}

@test "git commit with full loop evidence is allowed" {
  set_phase s-ready commit
  mark s-ready verify pass
  mark s-ready review pass
  mark s-ready postmortem done
  mark s-ready future-research skip
  run_pre "$(mkinput Bash s-ready "git commit -m test")"
  [ "$status" -eq 0 ]
  [ "$(last_event_field decision)" = "allow" ]
}

@test "sensitive evidence path is redacted" {
  export AGENTOPS_WORKFLOW_STATE_DIR="$WORK/.env-secret"
  export AGENTOPS_EVENT_LOG="$WORK/redacted-events.jsonl"
  mkdir -p "$AGENTOPS_WORKFLOW_STATE_DIR"
  run_pre "$(mkinput Edit s-redacted)"
  [ "$status" -eq 2 ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}

@test "mutation without mandatory context evidence is blocked" {
  unset AGENTOPS_CONTEXT_LOADED
  unset AGENTOPS_CONTEXT_WAIVED
  set_phase s-context-missing impl
  mark s-context-missing guardrail-verify pass
  run_pre "$(mkinput Edit s-context-missing)"
  [ "$status" -eq 2 ]
  [ "$(last_event_field failure_taxonomy)" = "context-evidence-missing" ]
  [ "$(last_event_field failure_class)" = "missing-context" ]
  [ "$(last_event_field context_source_id)" = "shared-agent-guide" ]
  [ "$(last_event_field approval_required)" = "true" ]
  [ "$(last_event_field approval_granted)" = "false" ]
}

@test "payload context_loaded emits context load evidence and allows mutation" {
  unset AGENTOPS_CONTEXT_LOADED
  set_phase s-context-loaded impl
  mark s-context-loaded guardrail-verify pass
  run_pre "$(mkinput_with_context s-context-loaded '[{"id":"shared-agent-guide","tokens_estimated":120},{"id":"agent-policy-modules","tokens_estimated":240}]')"
  [ "$status" -eq 0 ]
  jq -e 'select(.event_type == "agentops.context.load" and .context_source_id == "shared-agent-guide" and .context_tokens_estimated == 120 and .trust_label == "repository")' "$AGENTOPS_EVENT_LOG" >/dev/null
  jq -e 'select(.event_type == "agentops.context.load" and .context_source_id == "agent-policy-modules" and .context_tokens_estimated == 240)' "$AGENTOPS_EVENT_LOG" >/dev/null
  [ "$(last_event_field decision)" = "allow" ]
}

@test "payload context_waived emits waiver evidence and allows mutation" {
  unset AGENTOPS_CONTEXT_LOADED
  set_phase s-context-waived impl
  mark s-context-waived guardrail-verify pass
  run_pre "$(mkinput_with_context s-context-waived '["shared-agent-guide"]' | jq '.metadata.context_waived = [{"id":"agent-policy-modules","reason":"not relevant to doc-only edit"}]')"
  [ "$status" -eq 0 ]
  jq -e 'select(.event_type == "agentops.context.waive" and .context_source_id == "agent-policy-modules" and .waiver_reason == "not relevant to doc-only edit")' "$AGENTOPS_EVENT_LOG" >/dev/null
  [ "$(last_event_field decision)" = "allow" ]
}

@test "token-like evidence path is redacted" {
  export AGENTOPS_WORKFLOW_STATE_DIR="$WORK/project-token-cache"
  export AGENTOPS_EVENT_LOG="$WORK/token-events.jsonl"
  mkdir -p "$AGENTOPS_WORKFLOW_STATE_DIR"
  run_pre "$(mkinput Edit s-token)"
  [ "$status" -eq 2 ]
  [ "$(last_event_field evidence_path)" = "[redacted]" ]
}
