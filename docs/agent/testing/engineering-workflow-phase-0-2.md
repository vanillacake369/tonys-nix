# TDD Specification: Engineering Workflow Phases 0–2

## Test Layers

1. Pure shell/Bats tests for decision, routing, telemetry, and traceability.
2. Nix contract assertions for roles, workflow gates, and provider projections.
3. Existing hook regression suite.
4. Focused integration checks for installed runtime paths.

## Red Tests to Write First

### Decision Engine

- valid low-risk input → `AUTO_EXECUTE`
- repository-answerable uncertainty → `RESEARCH_REQUIRED`
- required unresolved question → `SPEC_QUESTION`
- missing approval for destructive work → `HUMAN_APPROVAL`
- missing approval for security-sensitive work → `HUMAN_APPROVAL`
- missing approval for migration/deployment/external/money work → `HUMAN_APPROVAL`
- explicit approval with matching scope → allowed action remains possible
- approval scope mismatch → `HUMAN_APPROVAL`
- explicit denial → `BLOCKED`
- policy violation → `BLOCKED`
- malformed JSON, missing decision ID, missing risk, or policy error → `BLOCKED`
- LLM `AUTO_EXECUTE` cannot override mandatory policy
- high uncertainty with no research path → `BLOCKED`

### Traceability Gate

- `proposed` and `specified` allow missing code/test/verification evidence
- `ready` and `in_progress` require design and test evidence
- `implemented` requires design/code/test/verification
- `verified` requires all evidence and existing referenced paths where local
- `deferred` and `rejected` require rationale but not code/test
- `blocked` requires blocker evidence
- duplicate IDs, unknown states, missing design, and malformed rows fail

### Telemetry

- valid decision appends exactly one JSONL event
- event contains required schema fields
- prompt text, secrets, and reasoning fields are absent
- missing decision fields fail without writing an event
- parent directory is created with restrictive permissions

### Router Integration

- route output contains the nested decision evidence
- complex/destructive/security/migration work cannot produce an auto action
- missing or uncertain policy input is fail-closed
- ordinary low-risk work does not require approval

### Command and Skill Surface

- public command registry contains only the four `cmd-vpp-*-ljh` entrypoints
- lifecycle capabilities use the `skl-*-ljh` namespace
- VPP-derived capabilities use `skl-vpp-*-ljh` lineage metadata
- legacy canonical workflow IDs remain available for compatibility but are not
  exported as additional commands
- skills cannot change permission, approval, or deterministic gate outcomes

### AI Harness Checklist

- sandbox and approval are separate policy fields
- the hook inventory covers pre-tool, post-tool, stop/completion, and
  orchestrator gates with deterministic exit behavior
- secret paths and dangerous commands are blocked before execution
- MCP allowlist rejects undeclared server/role/skill combinations
- project policy rejects attempts to weaken global deny rules
- evidence gate rejects missing commands, failed tests, unresolved errors, or
  missing commit linkage
- retry state remains blocked after the third failure and does not stash/reset
- reviewer permission profiles remain read-only
- memory rejects secret-like content and enforces daily/durable line limits
- external operation registry preserves idempotency and UNKNOWN status
- provider instruction verification distinguishes source reference from native
  import verification

## Definition of Green

- Every red test above passes.
- `just lint` passes.
- `just _test-guard` passes.
- `just test-hooks` passes.
- Codex/Kiro provider contract checks pass.
- No test relies on an external service or model availability.

## Phase 3–5 Test Contracts Only

These are not implemented now. Future work must add tests before behavior:

- Phase 3: approval UX, provider execution adapters, dependency graph enforcement.
- Phase 4: telemetry aggregation, ROI metrics, calibration dataset, retention.
- Phase 5: deployment/migration dry-run, rollback, external permission scopes,
  incident ownership and audit trail.
