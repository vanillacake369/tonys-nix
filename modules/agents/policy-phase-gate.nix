# Mixin: AgentOps workflow phase gate.
# Renders provider-native hooks from the declarative workflow registry.
{
  config,
  lib,
  pkgs,
  ...
}: let
  phaseGateProviders = lib.filterAttrs (_: p: p.enable && p.phases.enforced) config.agentPolicy.providers;
  workflowRuntime = config.agentPolicy.workflow;
  workflows = lib.filterAttrs (_: workflow: workflow.phases != {}) config.agentPolicy.registry.workflows;
  contextSources = config.agentPolicy.registry.repository.contextSources;
  telemetry = config.agentPolicy.telemetry;

  mkPattern = values: lib.concatStringsSep "|" (lib.unique values);
  mkAgentOpsEventShell = name:
    import ./runtime/agentops-event.nix {
      inherit lib telemetry;
      provider = name;
    };
  workflowNames = lib.attrNames workflows;
  markerExpr = ref: ''has_marker "$session" ${lib.escapeShellArg ref.phase} ${lib.escapeShellArg ref.result}'';
  entryGroupExpr = group:
    if group == []
    then "true"
    else "(" + lib.concatStringsSep " || " (map markerExpr group) + ")";
  entryExpr = phaseSpec:
    if phaseSpec.entry == []
    then "return 0"
    else lib.concatStringsSep " \\\n          && " (map entryGroupExpr phaseSpec.entry);
  mkPhaseEntryCases = _workflowName: workflow: let
    phaseNames = lib.attrNames workflow.phases;
  in ''
    ${lib.concatMapStringsSep "\n" (phaseName: ''
        ${phaseName}) ${entryExpr workflow.phases.${phaseName}} ;;
      '')
      phaseNames}
            *) return 1 ;;
  '';
  mkWorkflowEntryCases =
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
    in ''
            ${workflowName})
              case "$phase" in
      ${mkPhaseEntryCases workflowName workflow}
              esac
              ;;
    '')
    workflowNames;
  mkWorkflowPhasePatternCases =
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
      phaseNames = lib.attrNames workflow.phases;
      phasePattern = mkPattern phaseNames;
    in ''
      ${workflowName})
        case "$phase" in
          ${phasePattern}) return 0 ;;
          *) return 1 ;;
        esac
        ;;
    '')
    workflowNames;
  mkWorkflowMutationCases =
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
      mutationPhases = lib.attrNames (lib.filterAttrs (_: phase: phase.mutationAllowed) workflow.phases);
      phasePattern = mkPattern mutationPhases;
    in ''
      ${workflowName})
        case "$phase" in
          ${phasePattern}) return 0 ;;
          *) return 1 ;;
        esac
        ;;
    '')
    workflowNames;
  mkAllowedMutationPhaseCases =
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
      mutationPhases = lib.attrNames (lib.filterAttrs (_: phase: phase.mutationAllowed) workflow.phases);
    in ''
      ${workflowName}) printf '%s' ${lib.escapeShellArg (lib.concatStringsSep ", " mutationPhases)} ;;
    '')
    workflowNames;
  mkWorkflowRiskCases =
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
    in ''
      ${workflowName}) printf '%s' ${lib.escapeShellArg workflow.risk} ;;
    '')
    workflowNames;
  mkWorkflowContextCases =
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
      contextIds = workflow.mandatoryContext;
    in ''
      ${workflowName})
        ${lib.concatMapStringsSep "\n" (id: "printf '%s\\n' " + lib.escapeShellArg id) contextIds}
        ;;
    '')
    workflowNames;
  mkContextPathCases =
    lib.concatMapStringsSep "\n" (sourceId: let
      source = builtins.getAttr sourceId contextSources;
    in ''
      ${sourceId}) printf '%s' ${lib.escapeShellArg source.path} ;;
    '')
    (lib.attrNames contextSources);
  mkContextTrustCases =
    lib.concatMapStringsSep "\n" (sourceId: let
      source = builtins.getAttr sourceId contextSources;
    in ''
      ${sourceId}) printf '%s' ${lib.escapeShellArg source.trustLabel} ;;
    '')
    (lib.attrNames contextSources);
  mkVerifyCases = pass:
    lib.concatMapStringsSep "\n" (workflowName: let
      workflow = builtins.getAttr workflowName workflows;
      next =
        if pass
        then workflow.verifyPassNext
        else workflow.verifyFailNext;
    in
      lib.optionalString (workflow.verifyPhase != null && next != null) ''
        ${workflowName}:${workflow.verifyPhase}) printf '%s' ${lib.escapeShellArg next}; return 0 ;;
      '')
    workflowNames;

  commonShell = name: ''
        JQ="${lib.getExe' pkgs.jq "jq"}"
        CURL="${lib.getExe pkgs.curl}"
        SHA256SUM="${lib.getExe' pkgs.coreutils "sha256sum"}"
        STATE_DIR="''${AGENTOPS_WORKFLOW_STATE_DIR:-${workflowRuntime.stateDir}}"
        EVENT_LOG="''${AGENTOPS_EVENT_LOG:-${telemetry.eventLog}}"
        OTLP_ENDPOINT="''${AGENTOPS_OTLP_ENDPOINT:-${telemetry.otlp.endpoint}}"
        MARKER_SECRET="''${AGENTOPS_MARKER_SECRET:-}"
        mkdir -p "$STATE_DIR" "$(dirname "$EVENT_LOG")"

        sanitize_path() {
          local path="$1"
          case "$path" in
            *".env"*|*"credentials"*|*"secrets/"*|*"secret/"*|*"id_rsa"*|*"token"*|*"keychain"*|*"/.ssh/"*|*"/.gnupg/"*|*"/.aws/"*|*"/.kube/"*|*"/.config/gcloud/"*|*"/.azure/"*)
              printf '[redacted]'
              ;;
            *)
              printf '%s' "$path"
              ;;
          esac
        }

        hash_hex() {
          printf '%s' "$1" | "$SHA256SUM" | awk '{print $1}'
        }

        marker_signature() {
          local session="$1"
          local phase="$2"
          local result="$3"
          local source="$4"
          local command_hash="$5"
          local reason="$6"
          [[ -n "$MARKER_SECRET" ]] || return 1
          hash_hex "$MARKER_SECRET|$session|$phase|$result|$source|$command_hash|$reason"
        }

        marker_file() {
          local session="$1"
          local phase="$2"
          local result="$3"
          printf '%s/%s.%s.%s.json\n' "$STATE_DIR" "$session" "$phase" "$result"
        }

        context_file() {
          local session="$1"
          local source_id="$2"
          printf '%s/%s.context.%s.json\n' "$STATE_DIR" "$session" "$(hash_hex "$source_id" | cut -c1-16)"
        }

        phase_file() {
          printf '%s/%s.phase\n' "$STATE_DIR" "$1"
        }

        get_phase() {
          local session="$1"
          local file
          file="$(phase_file "$session")"
          if [[ -n "''${AGENTOPS_PHASE:-}" ]]; then
            printf '%s' "$AGENTOPS_PHASE"
          elif [[ -f "$file" ]]; then
            tr -d '[:space:]' < "$file"
          fi
        }

        set_phase() {
          local session="$1"
          local phase="$2"
          printf '%s' "$phase" > "$(phase_file "$session")"
        }

        write_marker() {
          local session="$1"
          local phase="$2"
          local result="$3"
          local source="$4"
          local command="$5"
          local reason="$6"
          local now command_hash signature
          now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
          command_hash=""
          if [[ -n "$command" ]]; then
            command_hash="$(hash_hex "$command")"
          fi
          signature="$(marker_signature "$session" "$phase" "$result" "$source" "$command_hash" "$reason" || true)"
          "$JQ" -cn \
            --arg schema_version "agentops.marker.v1" \
            --arg timestamp "$now" \
            --arg session_id "$session" \
            --arg phase "$phase" \
            --arg result "$result" \
            --arg source "$source" \
            --arg command_hash "$command_hash" \
            --arg reason "$reason" \
            --arg signature "$signature" \
            '{
              schema_version: $schema_version,
              timestamp: $timestamp,
              session_id: $session_id,
              phase: $phase,
              result: $result,
              source: $source,
              command_hash: $command_hash,
              reason: $reason,
              signature: $signature
            }' > "$(marker_file "$session" "$phase" "$result")"
        }

        valid_marker() {
          local session="$1"
          local phase="$2"
          local result="$3"
          local file
          file="$(marker_file "$session" "$phase" "$result")"
          [[ -f "$file" ]] || return 1
          [[ "$("$JQ" -r '.schema_version // ""' "$file" 2>/dev/null)" == "agentops.marker.v1" ]] || return 1
          [[ "$("$JQ" -r '.session_id // ""' "$file" 2>/dev/null)" == "$session" ]] || return 1
          [[ "$("$JQ" -r '.phase // ""' "$file" 2>/dev/null)" == "$phase" ]] || return 1
          [[ "$("$JQ" -r '.result // ""' "$file" 2>/dev/null)" == "$result" ]] || return 1
          local source
          source="$("$JQ" -r '.source // ""' "$file" 2>/dev/null)"
          [[ "$source" == "agentops-policy" || "$source" == "agentops-hook" ]] || return 1
          if [[ -n "$MARKER_SECRET" && "$source" == "agentops-hook" ]]; then
            local command_hash reason signature expected
            command_hash="$("$JQ" -r '.command_hash // ""' "$file" 2>/dev/null)"
            reason="$("$JQ" -r '.reason // ""' "$file" 2>/dev/null)"
            signature="$("$JQ" -r '.signature // ""' "$file" 2>/dev/null)"
            expected="$(marker_signature "$session" "$phase" "$result" "$source" "$command_hash" "$reason" || true)"
            [[ -n "$signature" && "$signature" == "$expected" ]] || return 1
          fi
        }

        has_marker() {
          local session="$1"
          local phase="$2"
          local result="$3"
          valid_marker "$session" "$phase" "$result"
        }

        ${mkAgentOpsEventShell name}

        context_path() {
          local source_id="$1"
          case "$source_id" in
    ${mkContextPathCases}
            *) printf "%s" "" ;;
          esac
        }

        context_trust_label() {
          local source_id="$1"
          case "$source_id" in
    ${mkContextTrustCases}
            *) printf "%s" "repository" ;;
          esac
        }

        mandatory_context_sources() {
          local workflow="$1"
          case "$workflow" in
    ${mkWorkflowContextCases}
            *) return 0 ;;
          esac
        }

        write_context_marker() {
          local session="$1"
          local workflow="$2"
          local slice="$3"
          local source_id="$4"
          local status="$5"
          local tokens="$6"
          local reason="$7"
          local now path trust event_type result taxonomy
          [[ -n "$source_id" ]] || return 0
          now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
          path="$(context_path "$source_id")"
          trust="$(context_trust_label "$source_id")"
          "$JQ" -cn \
            --arg schema_version "agentops.context.v1" \
            --arg timestamp "$now" \
            --arg session_id "$session" \
            --arg workflow_id "$workflow" \
            --arg slice_id "$slice" \
            --arg source_id "$source_id" \
            --arg status "$status" \
            --arg path "$path" \
            --arg trust "$trust" \
            --arg tokens "$tokens" \
            --arg reason "$reason" \
            '{
              schema_version: $schema_version,
              timestamp: $timestamp,
              session_id: $session_id,
              workflow_id: $workflow_id,
              slice_id: $slice_id,
              source_id: $source_id,
              status: $status,
              path: $path,
              trust_label: $trust,
              context_tokens_estimated: (if $tokens == "" then null else ($tokens | tonumber) end),
              waiver_reason: (if $reason == "" then null else $reason end)
            }' > "$(context_file "$session" "$source_id")"

          event_type="agentops.context.load"
          result="pass"
          taxonomy=""
          if [[ "$status" == "waived" ]]; then
            event_type="agentops.context.waive"
            result="skipped"
          fi
          AGENTOPS_EVENT_TYPE="$event_type" \
          AGENTOPS_HOOK_VERSION="context-evidence.v1" \
          AGENTOPS_POLICY_SOURCE="agentPolicy.registry.workflow.mandatoryContext" \
          AGENTOPS_CONTEXT_SOURCE_ID="$source_id" \
          AGENTOPS_CONTEXT_PATH="$path" \
          AGENTOPS_CONTEXT_TOKENS_ESTIMATED="$tokens" \
          AGENTOPS_CONTEXT_TRUST_LABEL="$trust" \
          AGENTOPS_CONTEXT_WAIVER_REASON="$reason" \
            emit_event "$session" "$workflow" "$slice" "unclassified" "ContextEvidence" "Context" "context-manager" "observe" "$result" "$taxonomy" "$path"
        }

        has_context_evidence() {
          local session="$1"
          local source_id="$2"
          local file
          file="$(context_file "$session" "$source_id")"
          [[ -f "$file" ]] || return 1
          [[ "$("$JQ" -r '.schema_version // ""' "$file" 2>/dev/null)" == "agentops.context.v1" ]] || return 1
          [[ "$("$JQ" -r '.session_id // ""' "$file" 2>/dev/null)" == "$session" ]] || return 1
          [[ "$("$JQ" -r '.source_id // ""' "$file" 2>/dev/null)" == "$source_id" ]] || return 1
          case "$("$JQ" -r '.status // ""' "$file" 2>/dev/null)" in
            loaded|waived) return 0 ;;
            *) return 1 ;;
          esac
        }

        ingest_context_evidence() {
          local session="$1"
          local workflow="$2"
          local slice="$3"
          local item source_id tokens reason
          if [[ -n "''${AGENTOPS_CONTEXT_LOADED:-}" ]]; then
            IFS=',' read -ra __loaded_sources <<< "$AGENTOPS_CONTEXT_LOADED"
            for source_id in "''${__loaded_sources[@]}"; do
              source_id="$(printf '%s' "$source_id" | xargs)"
              write_context_marker "$session" "$workflow" "$slice" "$source_id" loaded "" ""
            done
          fi
          if [[ -n "''${AGENTOPS_CONTEXT_WAIVED:-}" ]]; then
            IFS=',' read -ra __waived_sources <<< "$AGENTOPS_CONTEXT_WAIVED"
            for source_id in "''${__waived_sources[@]}"; do
              source_id="$(printf '%s' "$source_id" | xargs)"
              write_context_marker "$session" "$workflow" "$slice" "$source_id" waived "" "''${AGENTOPS_CONTEXT_WAIVER_REASON:-explicit waiver}"
            done
          fi
          while IFS= read -r item; do
            source_id="$(printf '%s' "$item" | "$JQ" -r 'if type == "string" then . else (.id // .source_id // "") end' 2>/dev/null)"
            tokens="$(printf '%s' "$item" | "$JQ" -r 'if type == "object" then (.tokens_estimated // .context_tokens_estimated // "") else "" end' 2>/dev/null)"
            case "$tokens" in ""|*[!0-9]*) tokens="" ;; esac
            write_context_marker "$session" "$workflow" "$slice" "$source_id" loaded "$tokens" ""
          done < <(printf '%s' "$INPUT" | "$JQ" -c '[(.context_loaded? // []), (.metadata.context_loaded? // [])] | flatten | .[]' 2>/dev/null || true)
          while IFS= read -r item; do
            source_id="$(printf '%s' "$item" | "$JQ" -r 'if type == "string" then . else (.id // .source_id // "") end' 2>/dev/null)"
            reason="$(printf '%s' "$item" | "$JQ" -r 'if type == "object" then (.reason // .waiver_reason // "explicit waiver") else "explicit waiver" end' 2>/dev/null)"
            write_context_marker "$session" "$workflow" "$slice" "$source_id" waived "" "$reason"
          done < <(printf '%s' "$INPUT" | "$JQ" -c '[(.context_waived? // []), (.metadata.context_waived? // [])] | flatten | .[]' 2>/dev/null || true)
        }

        missing_mandatory_context() {
          local workflow="$1"
          local session="$2"
          local source_id
          while IFS= read -r source_id; do
            [[ -n "$source_id" ]] || continue
            has_context_evidence "$session" "$source_id" || {
              printf '%s' "$source_id"
              return 0
            }
          done < <(mandatory_context_sources "$workflow")
          return 1
        }

        is_verify_command() {
          echo "$1" | grep -Eq '(nix[[:space:]]+flake[[:space:]]+check|nix[[:space:]]+build|bats[[:space:]]|go[[:space:]]+test|pytest|vitest|npm[[:space:]]+test|yarn[[:space:]]+test)'
        }

        is_mutation_command() {
          local command="$1"
          local scrubbed
          scrubbed="$(printf '%s' "$command" \
            | sed -E "s/[0-9]*>>?[[:space:]]*\/dev\/null//g; s/'[^']*'/__quoted__/g; s/\"[^\"]*\"/__quoted__/g")"
          echo "$scrubbed" | grep -Eq '(^|[;&|[:space:]])(git[[:space:]]+(commit|merge|rebase|cherry-pick|push|switch[[:space:]]+-c|checkout[[:space:]]+-b)|rm[[:space:]]|mv[[:space:]]|cp[[:space:]]|chmod[[:space:]]|chown[[:space:]]|mkdir[[:space:]]|touch[[:space:]]|install[[:space:]]|rsync[[:space:]]|tee([[:space:]]|$)|nix[[:space:]]+fmt|apply_patch|sed[[:space:]]+-i|perl[[:space:]]+-pi|python[0-9.]*[[:space:]]+-c|node[[:space:]]+-e|gh[[:space:]]+pr|kubectl[[:space:]]+(apply|create|delete|patch|scale)|terraform[[:space:]]+(apply|destroy|import)|helm[[:space:]]+(upgrade|install|uninstall))|(^|[^<[:alnum:]])[0-9]*>>?[[:space:]]*[^&[:space:]]'
        }

        phase_exists() {
          local workflow="$1"
          local phase="$2"
          case "$workflow" in
    ${mkWorkflowPhasePatternCases}
            *) return 1 ;;
          esac
        }

        mutation_phase_ok() {
          local workflow="$1"
          local phase="$2"
          case "$workflow" in
    ${mkWorkflowMutationCases}
            *) return 1 ;;
          esac
        }

        allowed_mutation_phases() {
          local workflow="$1"
          case "$workflow" in
    ${mkAllowedMutationPhaseCases}
            *) printf "%s" "" ;;
          esac
        }

        workflow_risk() {
          local workflow="$1"
          case "$workflow" in
    ${mkWorkflowRiskCases}
            *) printf "%s" "unknown" ;;
          esac
        }

        next_after_verify() {
          local workflow="$1"
          local phase="$2"
          local result="$3"
          case "$result" in
            pass)
              case "$workflow:$phase" in
    ${mkVerifyCases true}
                *) return 1 ;;
              esac
              ;;
            fail)
              case "$workflow:$phase" in
    ${mkVerifyCases false}
                *) return 1 ;;
              esac
              ;;
            *) return 1 ;;
          esac
        }

        phase_entry_ok() {
          local workflow="$1"
          local session="$2"
          local phase="$3"
          case "$workflow" in
    ${mkWorkflowEntryCases}
            *) return 1 ;;
          esac
        }
  '';

  mkPreScript = name: prov: let
    gatedTools = lib.unique (workflowRuntime.gatedTools ++ prov.phases.gatedTools);
    gatedPattern = mkPattern gatedTools;
  in
    pkgs.writeShellScript "agentops-workflow-gate-pre-${name}.sh" ''
      set -euo pipefail
      ${commonShell name}

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null)
      SESSION_ID=$(echo "$INPUT" | "$JQ" -r '.session_id // "default"' 2>/dev/null)
      WORKFLOW_ID=$(echo "$INPUT" | "$JQ" -r '.workflow_id // .metadata.workflow_id // "${workflowRuntime.defaultWorkflow}"' 2>/dev/null)
      SLICE_ID=$(echo "$INPUT" | "$JQ" -r '.slice_id // .metadata.slice_id // "default"' 2>/dev/null)
      AGENTOPS_WORKFLOW_RISK="$(workflow_risk "$WORKFLOW_ID")"
      AGENTOPS_SANDBOX_MODE=$(echo "$INPUT" | "$JQ" -r '.sandbox_mode // .metadata.sandbox_mode // .cwd_permission // "unknown"' 2>/dev/null)
      AGENTOPS_POLICY_SOURCE="agentPolicy.workflow.phase-gate"
      AGENTOPS_APPROVAL_SOURCE="workflow-evidence"
      AGENTOPS_APPROVAL_REQUIRED=false
      AGENTOPS_APPROVAL_GRANTED=null

      case "$TOOL_NAME" in
        ${gatedPattern}) ;;
        *) exit 0 ;;
      esac

      ingest_context_evidence "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID"

      PHASE="$(get_phase "$SESSION_ID")"
      COMMAND=""
      if [[ "$TOOL_NAME" == "Bash" ]]; then
        COMMAND=$(echo "$INPUT" | "$JQ" -r '.tool_input.command // empty' 2>/dev/null)
      fi

      if [[ -z "$PHASE" ]]; then
        if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" || "$TOOL_NAME" == "NotebookEdit" ]] || { [[ "$TOOL_NAME" == "Bash" ]] && is_mutation_command "$COMMAND"; }; then
          emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "block" "fail" "missing-phase" "$(phase_file "$SESSION_ID")"
          echo "[WORKFLOW:${name}] BLOCKED: mutation requires an active phase." >&2
          echo "Set phase evidence through the generated provider workflow state." >&2
          exit 2
        fi
        emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "observe" "skipped" "missing-phase" "$(phase_file "$SESSION_ID")"
        exit 0
      fi

      if ! phase_exists "$WORKFLOW_ID" "$PHASE"; then
          emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "block" "fail" "invalid-phase" "$(phase_file "$SESSION_ID")"
          echo "[WORKFLOW:${name}] BLOCKED: invalid phase '$PHASE' for workflow '$WORKFLOW_ID'." >&2
          exit 2
      fi

      IS_MUTATION=0
      case "$TOOL_NAME" in
        Write|Edit|NotebookEdit) IS_MUTATION=1 ;;
        Bash)
          if is_mutation_command "$COMMAND"; then
            IS_MUTATION=1
          fi
          ;;
      esac

      if [[ "$IS_MUTATION" == "1" ]]; then
        MISSING_CONTEXT="$(missing_mandatory_context "$WORKFLOW_ID" "$SESSION_ID" || true)"
        if [[ -n "$MISSING_CONTEXT" ]]; then
          AGENTOPS_APPROVAL_REQUIRED=true
          AGENTOPS_APPROVAL_GRANTED=false
          AGENTOPS_CONTEXT_SOURCE_ID="$MISSING_CONTEXT"
          AGENTOPS_CONTEXT_PATH="$(context_path "$MISSING_CONTEXT")"
          AGENTOPS_CONTEXT_TRUST_LABEL="$(context_trust_label "$MISSING_CONTEXT")"
          emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "block" "fail" "context-evidence-missing" "$STATE_DIR/$SESSION_ID"
          echo "[WORKFLOW:${name}] BLOCKED: mutation requires mandatory context evidence '$MISSING_CONTEXT'." >&2
          echo "Load or explicitly waive required context before mutation." >&2
          exit 2
        fi
      fi

      if ! phase_entry_ok "$WORKFLOW_ID" "$SESSION_ID" "$PHASE"; then
        AGENTOPS_APPROVAL_REQUIRED=true
        AGENTOPS_APPROVAL_GRANTED=false
        emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "block" "fail" "entry-evidence-missing" "$STATE_DIR/$SESSION_ID"
        echo "[WORKFLOW:${name}] BLOCKED: phase '$PHASE' is missing required entry evidence." >&2
        if [[ "$PHASE" == "commit" ]]; then
          echo "Required before commit: verify.pass, review.pass, postmortem done/skip, future-research done/skip." >&2
        fi
        exit 2
      fi

      if [[ "$IS_MUTATION" != "1" ]]; then
        emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "allow" "pass" "" "$(phase_file "$SESSION_ID")"
        exit 0
      fi

      if ! mutation_phase_ok "$WORKFLOW_ID" "$PHASE"; then
          AGENTOPS_APPROVAL_REQUIRED=true
          AGENTOPS_APPROVAL_GRANTED=false
          emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "block" "fail" "mutation-outside-phase" "$(phase_file "$SESSION_ID")"
          echo "[WORKFLOW:${name}] BLOCKED: mutation tool '$TOOL_NAME' is not allowed during phase '$PHASE'." >&2
          echo "Allowed mutation phases: $(allowed_mutation_phases "$WORKFLOW_ID")" >&2
          exit 2
      fi

      if [[ "$TOOL_NAME" == "Bash" ]] && echo "$COMMAND" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)'; then
        if [[ "$PHASE" != "commit" ]] || ! phase_entry_ok "$WORKFLOW_ID" "$SESSION_ID" commit; then
          AGENTOPS_APPROVAL_REQUIRED=true
          AGENTOPS_APPROVAL_GRANTED=false
          emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "block" "fail" "commit-before-evidence" "$STATE_DIR/$SESSION_ID"
          echo "[WORKFLOW:${name}] BLOCKED: git commit requires verify, review, postmortem, and future-research evidence." >&2
          exit 2
        fi
      fi

      emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PreToolUse" "$TOOL_NAME" "guardrail-designer" "allow" "pass" "" "$(phase_file "$SESSION_ID")"
      exit 0
    '';

  mkPostScript = name: _prov:
    pkgs.writeShellScript "agentops-workflow-gate-post-${name}.sh" ''
      set -euo pipefail
      ${commonShell name}

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | "$JQ" -r '.tool_name // empty' 2>/dev/null)
      [[ "$TOOL_NAME" == "Bash" ]] || exit 0

      SESSION_ID=$(echo "$INPUT" | "$JQ" -r '.session_id // "default"' 2>/dev/null)
      WORKFLOW_ID=$(echo "$INPUT" | "$JQ" -r '.workflow_id // .metadata.workflow_id // "${workflowRuntime.defaultWorkflow}"' 2>/dev/null)
      SLICE_ID=$(echo "$INPUT" | "$JQ" -r '.slice_id // .metadata.slice_id // "default"' 2>/dev/null)
      AGENTOPS_WORKFLOW_RISK="$(workflow_risk "$WORKFLOW_ID")"
      AGENTOPS_SANDBOX_MODE=$(echo "$INPUT" | "$JQ" -r '.sandbox_mode // .metadata.sandbox_mode // .cwd_permission // "unknown"' 2>/dev/null)
      AGENTOPS_POLICY_SOURCE="agentPolicy.workflow.phase-gate"
      AGENTOPS_APPROVAL_SOURCE="workflow-evidence"
      AGENTOPS_APPROVAL_REQUIRED=false
      AGENTOPS_APPROVAL_GRANTED=null
      COMMAND=$(echo "$INPUT" | "$JQ" -r '.tool_input.command // empty' 2>/dev/null)
      EXIT_CODE=$(echo "$INPUT" | "$JQ" -r '.tool_exit_code // .tool_response.exit_code // .exit_code // 0' 2>/dev/null)
      PHASE="$(get_phase "$SESSION_ID")"

      NEXT_PASS="$(next_after_verify "$WORKFLOW_ID" "$PHASE" pass || true)"
      NEXT_FAIL="$(next_after_verify "$WORKFLOW_ID" "$PHASE" fail || true)"
      [[ -n "$NEXT_PASS" && -n "$NEXT_FAIL" ]] || exit 0
      is_verify_command "$COMMAND" || exit 0

      if [[ "$EXIT_CODE" == "0" ]]; then
        write_marker "$SESSION_ID" "$PHASE" pass agentops-hook "$COMMAND" ""
        set_phase "$SESSION_ID" "$NEXT_PASS"
        emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PostToolUse" "$TOOL_NAME" "tester" "allow" "pass" "" "$(marker_file "$SESSION_ID" "$PHASE" pass)"
      else
        write_marker "$SESSION_ID" "$PHASE" fail agentops-hook "$COMMAND" "verify command failed"
        set_phase "$SESSION_ID" "$NEXT_FAIL"
        emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "$PHASE" "PostToolUse" "$TOOL_NAME" "tester" "warn" "fail" "verify-failed" "$(marker_file "$SESSION_ID" "$PHASE" fail)"
      fi
      exit 0
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (workflowRuntime.enabled && phaseGateProviders != {}) {
    workflow-gate-pre =
      lib.mapAttrs (name: prov: {
        event = "PreToolUse";
        matcher = mkPattern (lib.unique (workflowRuntime.gatedTools ++ prov.phases.gatedTools));
        script = mkPreScript name prov;
      })
      phaseGateProviders;

    workflow-gate-post =
      lib.mapAttrs (name: prov: {
        event = "PostToolUse";
        matcher = "Bash";
        script = mkPostScript name prov;
      })
      phaseGateProviders;
  };
}
