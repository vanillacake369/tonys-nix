{
  lib,
  telemetry,
  provider,
}: ''
  failure_class() {
    case "$1" in
      missing-phase|invalid-phase|entry-evidence-missing|context-evidence-missing) printf 'missing-context' ;;
      mutation-outside-phase|commit-before-evidence) printf 'wrong-tool' ;;
      verify-failed) printf 'verification-failure' ;;
      permission-denied) printf 'permission-failure' ;;
      budget-exhausted) printf 'budget-exhaustion' ;;
      "") printf "" ;;
      *) printf 'policy-violation' ;;
    esac
  }

  emit_otlp() {
    local event_json="$1"
    [[ "${lib.boolToString telemetry.otlp.enabled}" != "true" ]] && return 0
    local session workflow slice phase hook tool decision result taxonomy class evidence event_type hook_version risk operation sandbox approval_required approval_granted approval_source policy_source context_source context_path context_tokens trust_label waiver_reason ts trace_id span_id status_code
    session="$(printf '%s' "$event_json" | "$JQ" -r '.session_id')"
    workflow="$(printf '%s' "$event_json" | "$JQ" -r '.workflow_id')"
    slice="$(printf '%s' "$event_json" | "$JQ" -r '.slice_id')"
    phase="$(printf '%s' "$event_json" | "$JQ" -r '.phase')"
    hook="$(printf '%s' "$event_json" | "$JQ" -r '.hook_event')"
    tool="$(printf '%s' "$event_json" | "$JQ" -r '.tool_name')"
    decision="$(printf '%s' "$event_json" | "$JQ" -r '.decision')"
    result="$(printf '%s' "$event_json" | "$JQ" -r '.result')"
    taxonomy="$(printf '%s' "$event_json" | "$JQ" -r '.failure_taxonomy')"
    class="$(printf '%s' "$event_json" | "$JQ" -r '.failure_class')"
    evidence="$(printf '%s' "$event_json" | "$JQ" -r '.evidence_path')"
    event_type="$(printf '%s' "$event_json" | "$JQ" -r '.event_type // "agentops.workflow_gate"')"
    hook_version="$(printf '%s' "$event_json" | "$JQ" -r '.hook_version // "workflow-gate.v1"')"
    risk="$(printf '%s' "$event_json" | "$JQ" -r '.risk_level // "unknown"')"
    operation="$(printf '%s' "$event_json" | "$JQ" -r '.operation_id // ""')"
    sandbox="$(printf '%s' "$event_json" | "$JQ" -r '.sandbox_mode // "unknown"')"
    approval_required="$(printf '%s' "$event_json" | "$JQ" -r '.approval_required // false')"
    approval_granted="$(printf '%s' "$event_json" | "$JQ" -r '.approval_granted // "null"')"
    approval_source="$(printf '%s' "$event_json" | "$JQ" -r '.approval_source // "policy-hook"')"
    policy_source="$(printf '%s' "$event_json" | "$JQ" -r '.policy_source // "agentPolicy.runtime"')"
    context_source="$(printf '%s' "$event_json" | "$JQ" -r '.context_source_id // ""')"
    context_path="$(printf '%s' "$event_json" | "$JQ" -r '.context_path // ""')"
    context_tokens="$(printf '%s' "$event_json" | "$JQ" -r '.context_tokens_estimated // ""')"
    trust_label="$(printf '%s' "$event_json" | "$JQ" -r '.trust_label // ""')"
    waiver_reason="$(printf '%s' "$event_json" | "$JQ" -r '.waiver_reason // ""')"
    ts="$(date +%s%N)"
    trace_id="$(hash_hex "$session|$workflow|$slice" | cut -c1-32)"
    span_id="$(hash_hex "$session|$workflow|$slice|$phase|$hook|$tool|$decision|$ts" | cut -c1-16)"
    status_code=1
    if [[ "$decision" == "block" || "$result" == "fail" ]]; then
      status_code=2
    fi
    "$JQ" -cn \
      --arg trace_id "$trace_id" \
      --arg span_id "$span_id" \
      --arg name "agentops.$phase" \
      --arg ts "$ts" \
      --arg phase "$phase" \
      --arg tool "$tool" \
      --arg workflow "$workflow" \
      --arg slice "$slice" \
      --arg event_type "$event_type" \
      --arg hook_version "$hook_version" \
      --arg risk "$risk" \
      --arg operation "$operation" \
      --arg decision "$decision" \
      --arg result "$result" \
      --arg taxonomy "$taxonomy" \
      --arg class "$class" \
      --arg evidence "$evidence" \
      --arg sandbox "$sandbox" \
      --arg approval_required "$approval_required" \
      --arg approval_granted "$approval_granted" \
      --arg approval_source "$approval_source" \
      --arg policy_source "$policy_source" \
      --arg context_source "$context_source" \
      --arg context_path "$context_path" \
      --arg context_tokens "$context_tokens" \
      --arg trust_label "$trust_label" \
      --arg waiver_reason "$waiver_reason" \
      --argjson status_code "$status_code" \
      '{
        resourceSpans: [{
          resource: {attributes: [
            {key: "service.name", value: {stringValue: "tonys-nix-agentops"}},
            {key: "gen_ai.system", value: {stringValue: "agentops"}},
            {key: "agentops.otlp.schema_version", value: {stringValue: "agentops.otlp.v1"}},
            {key: "agentops.event.schema_version", value: {stringValue: "agentops.event.v1"}}
          ]},
          scopeSpans: [{
            spans: [{
              traceId: $trace_id,
              spanId: $span_id,
              name: $name,
              startTimeUnixNano: $ts,
              endTimeUnixNano: $ts,
              attributes: [
                {key: "gen_ai.operation.name", value: {stringValue: $name}},
                {key: "gen_ai.tool.name", value: {stringValue: $tool}},
                {key: "agentops.workflow_id", value: {stringValue: $workflow}},
                {key: "agentops.slice_id", value: {stringValue: $slice}},
                {key: "agentops.event_type", value: {stringValue: $event_type}},
                {key: "agentops.risk_level", value: {stringValue: $risk}},
                {key: "agentops.operation_id", value: {stringValue: $operation}},
                {key: "agentops.phase", value: {stringValue: $phase}},
                {key: "agentops.decision", value: {stringValue: $decision}},
                {key: "agentops.result", value: {stringValue: $result}},
                {key: "agentops.failure_taxonomy", value: {stringValue: $taxonomy}},
                {key: "agentops.failure_class", value: {stringValue: $class}},
                {key: "agentops.evidence_path", value: {stringValue: $evidence}},
                {key: "agentops.approval.required", value: {stringValue: $approval_required}},
                {key: "agentops.approval.granted", value: {stringValue: $approval_granted}},
                {key: "agentops.approval.source", value: {stringValue: $approval_source}},
                {key: "agentops.sandbox.mode", value: {stringValue: $sandbox}},
                {key: "agentops.policy.source", value: {stringValue: $policy_source}},
                {key: "agentops.context.source_id", value: {stringValue: $context_source}},
                {key: "agentops.context.path", value: {stringValue: $context_path}},
                {key: "agentops.context.tokens_estimated", value: {stringValue: $context_tokens}},
                {key: "agentops.context.trust_label", value: {stringValue: $trust_label}},
                {key: "agentops.context.waiver_reason", value: {stringValue: $waiver_reason}},
                {key: "agentops.decision.reason", value: {stringValue: $taxonomy}},
                {key: "agentops.policy.version", value: {stringValue: "agent-policy.v1"}},
                {key: "agentops.registry.version", value: {stringValue: "agentops-registry.v1"}},
                {key: "agentops.hook.version", value: {stringValue: $hook_version}}
              ],
              status: {code: $status_code}
            }]
          }]
        }]
      }' | "$CURL" -fsS --max-time 1 -H 'Content-Type: application/json' --data-binary @- "$OTLP_ENDPOINT" >/dev/null 2>&1 || true
  }

  emit_event() {
    local session="$1"
    local workflow="$2"
    local slice="$3"
    local phase="$4"
    local hook="$5"
    local tool="$6"
    local capability="$7"
    local decision="$8"
    local result="$9"
    local taxonomy="''${10}"
    local evidence="''${11}"
    [[ "${lib.boolToString telemetry.enabled}" != "true" ]] && return 0
    local now event class event_id event_type hook_version success risk operation_id sandbox approval_required approval_granted approval_source policy_source context_source context_path context_tokens trust_label waiver_reason
    now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    case "$taxonomy" in
      sensitive-path*) evidence="[redacted]" ;;
      *) evidence="$(sanitize_path "$evidence")" ;;
    esac
    class="$(failure_class "$taxonomy")"
    event_type="''${AGENTOPS_EVENT_TYPE:-agentops.workflow_gate}"
    hook_version="''${AGENTOPS_HOOK_VERSION:-workflow-gate.v1}"
    event_id="$(hash_hex "$session|$workflow|$slice|$phase|$hook|$tool|$decision|$result|$now" | cut -c1-32)"
    operation_id="$(hash_hex "$session|$workflow|$slice|$phase|$hook|$tool|$decision" | cut -c1-32)"
    risk="''${AGENTOPS_WORKFLOW_RISK:-unknown}"
    sandbox="''${AGENTOPS_SANDBOX_MODE:-unknown}"
    approval_required="''${AGENTOPS_APPROVAL_REQUIRED:-false}"
    approval_granted="''${AGENTOPS_APPROVAL_GRANTED:-null}"
    approval_source="''${AGENTOPS_APPROVAL_SOURCE:-policy-hook}"
    policy_source="''${AGENTOPS_POLICY_SOURCE:-agentPolicy.runtime}"
    context_source="''${AGENTOPS_CONTEXT_SOURCE_ID:-}"
    context_path="''${AGENTOPS_CONTEXT_PATH:-}"
    context_tokens="''${AGENTOPS_CONTEXT_TOKENS_ESTIMATED:-}"
    trust_label="''${AGENTOPS_CONTEXT_TRUST_LABEL:-}"
    waiver_reason="''${AGENTOPS_CONTEXT_WAIVER_REASON:-}"
    case "$context_tokens" in
      ""|*[!0-9]*) context_tokens="" ;;
    esac
    success=null
    case "$result" in
      pass|skipped) success=true ;;
      fail) success=false ;;
    esac
    event="$("$JQ" -cn \
      --arg schemaVersion "${telemetry.schemaVersion}" \
      --arg schema_version "${telemetry.schemaVersion}" \
      --arg event_id "$event_id" \
      --arg run_id "$session" \
      --arg timestamp "$now" \
      --arg event_type "$event_type" \
      --arg hook_version "$hook_version" \
      --arg session_id "$session" \
      --arg workflow "$workflow" \
      --arg workflow_id "$workflow" \
      --arg risk_level "$risk" \
      --arg operation_id "$operation_id" \
      --arg slice_id "$slice" \
      --arg phase "''${phase:-unclassified}" \
      --arg capability "$capability" \
      --arg executor "${provider}" \
      --arg provider "${provider}" \
      --arg surface "${provider}" \
      --arg hook_event "$hook" \
      --arg tool_name "$tool" \
      --arg decision "$decision" \
      --arg result "$result" \
      --arg failure_taxonomy "$taxonomy" \
      --arg failure_class "$class" \
      --arg retry_count "0" \
      --arg evidence_path "$evidence" \
      --arg artifact_path "$evidence" \
      --argjson success "$success" \
      --arg sandbox_mode "$sandbox" \
      --arg approval_source "$approval_source" \
      --arg policy_source "$policy_source" \
      --arg context_source_id "$context_source" \
      --arg context_path "$context_path" \
      --arg context_tokens_estimated "$context_tokens" \
      --arg trust_label "$trust_label" \
      --arg waiver_reason "$waiver_reason" \
      --argjson approval_required "$approval_required" \
      --argjson approval_granted "$approval_granted" \
      '{
        schemaVersion: $schemaVersion,
        schema_version: $schema_version,
        event_id: $event_id,
        run_id: $run_id,
        timestamp: $timestamp,
        event_type: $event_type,
        provider: $provider,
        surface: $surface,
        workflow: $workflow,
        risk_level: $risk_level,
        operation_id: $operation_id,
        tool_name: $tool_name,
        success: $success,
        error_type: (if $failure_taxonomy == "" then null else $failure_taxonomy end),
        artifact_path: (if $artifact_path == "" then null else $artifact_path end),
        artifact_hash: null,
        content_capture: false,
        hook_version: $hook_version,
        approval_required: $approval_required,
        approval_granted: $approval_granted,
        approval_source: $approval_source,
        sandbox_mode: $sandbox_mode,
        policy_source: $policy_source,
        context_source_id: (if $context_source_id == "" then null else $context_source_id end),
        context_path: (if $context_path == "" then null else $context_path end),
        context_tokens_estimated: (if $context_tokens_estimated == "" then null else ($context_tokens_estimated | tonumber) end),
        trust_label: (if $trust_label == "" then null else $trust_label end),
        waiver_reason: (if $waiver_reason == "" then null else $waiver_reason end),

        session_id: $session_id,
        workflow_id: $workflow_id,
        slice_id: $slice_id,
        phase: $phase,
        capability: $capability,
        executor: $executor,
        hook_event: $hook_event,
        decision: $decision,
        result: $result,
        failure_taxonomy: $failure_taxonomy,
        failure_class: $failure_class,
        retry_count: ($retry_count | tonumber),
        evidence_path: $evidence_path
      }')"
    printf '%s\n' "$event" >> "$EVENT_LOG"
    emit_otlp "$event"
  }
''
