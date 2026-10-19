# PRD: Minimum Verifiable Engineering Workflow — Phases 0–2

## Problem Statement

The repository has provider-neutral roles and workflows, but route selection,
mandatory approval, requirement evidence, and decision telemetry are not yet
connected into one fail-closed workflow. A model could recommend skipping an
approval or a user could omit a PRD and avoid traceability unintentionally.

## Solution

Add a provider-neutral Decision Engine around the existing route and
traceability scripts. PRD Markdown remains the source of truth. A state-aware
TSV index links requirements to design, code, tests, and verification. A
deterministic policy engine dominates the untrusted LLM Judge recommendation.
Complex, destructive, security-sensitive, migration, deployment, external
resource, and money-related work requires scoped human approval. Missing or
invalid policy information fails closed. Each decision emits minimal JSONL
telemetry without prompts or reasoning traces.

## User Stories

1. As an engineer, I want to classify work by risk and uncertainty, so that simple work stays fast and risky work receives ceremony.
2. As an engineer, I want repository-answerable uncertainty to select research, so that unnecessary user questions are avoided.
3. As a product owner, I want critical unresolved requirements to block implementation, so that agents do not guess business behavior.
4. As a reviewer, I want requirement IDs linked to design, code, tests, and verification, so that completion claims are auditable.
5. As an operator, I want deployment and data changes to require scoped approval, so that an agent cannot perform operational mutations implicitly.
6. As a security reviewer, I want mandatory security policy to override an LLM recommendation, so that model output cannot weaken guardrails.
7. As an approver, I want an approval tied to a request scope digest, so that materially changed work requires re-approval.
8. As an engineer, I want denied, malformed, or missing policy information to block safely, so that uncertainty does not become permission.
9. As a maintainer, I want a small JSONL decision record, so that later telemetry can measure behavior without storing sensitive prompts.
10. As a provider maintainer, I want the decision contract shared by Codex and Kiro, so that provider adapters do not fork policy.

## Requirements

### FR-001 — State-aware traceability

- Status: ready
- The PRD is the SSoT.
- The TSV is an index keyed by unique requirement ID and explicit requirement state.
- Validation rules vary by requirement state.

### FR-002 — Risk-based route

- Status: ready
- Router considers change scope, risk signals, uncertainty, reversibility, and external impact.
- The output includes complexity, route, workflows, and decision action.

### FR-003 — Deterministic policy precedence

- Status: ready
- Policy engine overrides LLM recommendations for mandatory gates.
- Policy failures and malformed input return `BLOCKED`.

### FR-004 — Scoped human approval

- Status: ready
- Complex, destructive, security-sensitive, migration, deployment, external resource, and money-related work cannot auto-execute without valid approval.
- Approval scope changes require re-approval.

### FR-005 — Spec question policy

- Status: ready
- Repository-answerable uncertainty returns `RESEARCH_REQUIRED`.
- Important unanswered requirements return `SPEC_QUESTION`.
- Non-critical assumptions may proceed only when risk is low and assumptions are recorded.

### FR-006 — Decision evidence

- Status: ready
- Every decision returns the required evidence fields defined in the architecture document.

### FR-007 — Minimum telemetry

- Status: ready
- Each decision can append one sanitized JSONL event.
- Prompts, secrets, credentials, and chain-of-thought are excluded.

### FR-008 — Provider compatibility

- Status: ready
- Existing Codex/Kiro role and workflow rendering remains valid.

### FR-009 — Local PRD presence gate

- Status: ready
- Risk-bearing repository changes require at least one `docs/agent/prd/*.md` artifact.
- Documentation-only and low-risk test-only changes are not forced to create a PRD.

### FR-010 — Command and skill surface naming

- Status: ready
- Explicit provider-facing commands use the `cmd-*` namespace.
- Project-owned lifecycle skills use the `skl-*-ljh` namespace.
- Absorbed VPP team-guideline capabilities use the `skl-vpp-*-ljh` namespace.
- The default command surface contains only `cmd-vpp-work-ljh`,
  `cmd-vpp-comment-ljh`, `cmd-vpp-handoff-ljh`, and `cmd-vpp-ship-ljh`.
- Existing workflow IDs remain stable migration identifiers for traceability,
  telemetry, and provider compatibility.
- The four-command surface is implemented; the current six canonical workflow
  IDs remain only as non-public legacy identifiers.

### FR-011 — Skill and command boundary

- Status: ready
- Reusable research, design, review, performance, documentation, and evidence
  capabilities are skills, not independent commands.
- Commands are reserved for explicit user entrypoints, repository/external
  state changes, or operations requiring a Human Gate.
- A skill cannot grant permissions or bypass deterministic policy.

### FR-012 — VPP guideline absorption

- Status: ready
- `clarify`, `grill-with-docs`, and `to-prd` are absorbed by `skl-pre-prd-ljh`.
- Repository research and bootstrap guidance is absorbed by
  `skl-pre-research-ljh`.
- ADR and strategy guidance is absorbed by `skl-pre-adr-ljh`.
- Code safety and review guidance is absorbed by `skl-mid-impl-ljh` and
  `skl-mid-review-ljh`.
- `ship` and `handoff` remain explicitly gated through post-phase skills and
  commands.

### FR-013 — AI harness verification checklist

- Status: ready
- Maintain a checklist covering sandbox, hook types, MCP purpose and
  authorization, command/skill boundaries, project harness selection, evidence
  completion, retry budget, provider instruction SSoT, reviewer isolation,
  memory lifecycle, idempotent external operations, and Git completion state.
- Classify each item as `satisfied`, `partial`, or `not-satisfied`.
- A `partial` item MUST identify its missing provider/runtime/external adapter
  and owning future phase; prose claims alone are not completion evidence.

### FR-014 — Deterministic hook and sandbox boundary

- Status: ready
- Secret-path and destructive-command restrictions MUST use a deterministic
  pre-execution boundary where native hooks exist and the shared runtime gate
  otherwise.
- Sandbox scope and approval policy MUST remain separate fields.
- LLM Judge and Review Gate MUST NOT grant permissions or weaken policy.

### FR-015 — MCP usage and authorization

- Status: ready
- Every MCP use MUST identify server, role, skill, operation risk, and evidence.
- Read-oriented MCP use MAY proceed under an allowlist; external mutation MUST
  require Human Gate and idempotency registration.
- Timeout or ambiguous response MUST remain `UNKNOWN` until provider state is
  queried.

### FR-016 — Provider instruction compatibility

- Status: ready
- `tonys-agent-harness/AGENTS.md` is the behavioral SSoT.
- Provider-specific import semantics MUST be verified against the installed
  provider version before being marked `satisfied`.
- Reference grep alone MUST NOT prove native import behavior.

### FR-017 — Memory lifecycle safety

- Status: ready
- Session, daily, and durable memory MUST be namespace-isolated and secret-free.
- Daily summaries are limited to 40 lines and durable knowledge to 120 lines.
- Automatic promotion, expiry, and conflict resolution are deferred until the
  owning phase and MUST not be implied by the MVP.

## Acceptance Criteria

- [ ] Low-risk, low-uncertainty request returns `AUTO_EXECUTE`.
- [ ] Repository-answerable request returns `RESEARCH_REQUIRED`.
- [ ] Missing critical requirement returns `SPEC_QUESTION`.
- [ ] Destructive, deployment, migration, security, external-resource, and money operations without approval return `HUMAN_APPROVAL`.
- [ ] Explicit denial or policy violation returns `BLOCKED`.
- [ ] Missing decision ID, malformed approval, policy-engine error, or missing risk information returns `BLOCKED`.
- [ ] Approval digest mismatch returns `HUMAN_APPROVAL`.
- [ ] An LLM `AUTO_EXECUTE` recommendation cannot bypass a mandatory policy.
- [ ] State-aware traceability accepts proposed/deferred rows without code/test evidence and requires all evidence for verified rows.
- [ ] Telemetry JSONL contains only the minimum schema and no raw prompt.
- [ ] Existing Codex/Kiro contract and hook tests remain green.
- [ ] The target public surface is specified as only the four
  `cmd-vpp-*-ljh` commands; migration tests prevent new command growth.
- [ ] Lifecycle skills are discoverable under the `skl-*-ljh` namespace and do
  not become independent mutation entrypoints.
- [ ] VPP source lineage is recorded without duplicating a second public command
  tree.
- [ ] The complete checklist is stored at
  `docs/agent/architecture/ai-harness-checklist.md` and every item has a status.
- [ ] Partial provider or external integrations are assigned to a later phase
  and cannot be reported as satisfied by schema presence alone.

## Implementation Decisions

- Shell and `jq` are reused; no new framework or external dependency is introduced.
- `route.sh` remains the provider-neutral entry point.
- `decision.sh` is a pure stdin/stdout policy boundary.
- `telemetry.sh` appends sanitized events only after a decision is produced.
- PRD state is read from an explicit TSV state column or normalized PRD metadata supplied by the caller; the gate never guesses state from prose.
- Actual deployment, migration, push, merge, and external resource mutation remain outside this phase.
- The naming contract is documented under `docs/agent/architecture/naming.md` and
  is not itself permission to rename or delete existing canonical workflow IDs.

## Testing Decisions

- Bats tests cover each decision action and policy precedence.
- Contract tests cover new workflow/gate metadata and provider projection.
- Traceability fixtures cover every supported state and malformed input.
- Regression tests cover existing route outputs, Codex/Kiro rendering, and hooks.
- Tests assert evidence fields and absence of raw prompt content in telemetry.

## Out of Scope

- Phase 3 implementation adapters.
- Phase 4 dashboards, ROI analysis, threshold tuning, and policy learning.
- Phase 5 deployment, SRE, migration, Jira, Confluence, GitHub, or MCP execution.
- Automatic approval or approval inference.

## Further Notes

Phase 3–5 PRDs and design dependencies are documented in
`docs/agent/architecture/engineering-system.md`, but no Phase 3–5 product behavior
is implemented by this change.
