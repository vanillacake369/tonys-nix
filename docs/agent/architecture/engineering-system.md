# Codex Engineering System Architecture

## Status

This document defines the target architecture for Phases 0–5. Only Phases 0–2
are implemented in the current change. Phases 3–5 describe contracts and
activation conditions only; they do not implement product functionality.

## Design Principles

1. Deterministic policy precedes agent reasoning.
2. An LLM may recommend an action but cannot relax a mandatory policy.
3. Evidence is a first-class input and output, not a prose claim.
4. One repository writer owns mutations; read-only analysis may be parallel.
5. The smallest safe route is selected from risk, uncertainty, blast radius,
   and reversibility—not file count alone.
6. Every phase has an independently testable contract and an explicit exit gate.

## Public Command and Skill Facade

Provider surfaces expose four explicit commands. Lifecycle capabilities are
provided as skills and selected by the orchestrator rather than exposed as
independent commands.

This surface is implemented. The existing six canonical workflow IDs remain in
the legacy registry for traceability and compatibility, but provider adapters
do not export them as public commands. No new canonical public workflow IDs may
be added without updating this contract.

### Public commands

| Public command | Responsibility |
|---|---|
| `cmd-vpp-work-ljh` | route work and select the minimum safe lifecycle path |
| `cmd-vpp-comment-ljh` | generate scoped code comments and change explanations |
| `cmd-vpp-handoff-ljh` | produce handoff and operational context artifacts |
| `cmd-vpp-ship-ljh` | prepare explicitly approved release or external operations |

### Lifecycle skills

| Skill | Primary owner | Absorbed responsibilities |
|---|---|---|
| `skl-pre-prd-ljh` | requirement-designer | clarify, domain glossary, PRD synthesis |
| `skl-pre-research-ljh` | research-engineer | repository archaeology, technology research, bootstrap |
| `skl-pre-adr-ljh` | decision-synthesizer | strategy A/B, cross-validation, ADR |
| `skl-mid-impl-ljh` | implementer | TDD, code/infra design, implementation, refactoring |
| `skl-mid-review-ljh` | independent-reviewer | security, code, evidence, and independent review |
| `skl-mid-perf-ljh` | performance-engineer | measurement and optimization |
| `skl-post-ship-ljh` | release/SRE capability | release preparation, approval, rollback planning |
| `skl-post-docs-ljh` | documentation-engineer | documentation, handoff, runbooks, issues |
| `skl-phase-route-ljh` | orchestrator | risk/uncertainty routing and workflow composition |
| `skl-phase-gate-ljh` | policy/execution gate | deterministic approval and fail-closed enforcement |
| `skl-phase-trace-ljh` | evidence capability | traceability, telemetry, retry, Git lifecycle |

Remaining workflow contracts stay in the legacy registry during the
transition. They are not exported to default Codex, Claude, or Kiro workflow
surfaces. Their source files remain available as migration material and are
absorbed into the lifecycle skills above; removal requires usage evidence and a
separate review. Existing canonical IDs remain stable for traceability and
telemetry compatibility.

## Phase Model

```text
Phase 0: Contract and Evidence Foundation
  PRD SSoT + stateful traceability index + schemas + deterministic gates
       ↓
Phase 1: Risk-based Decision Engine
  LLM Judge input + deterministic Policy Engine + fail-closed Decision Router
       ↓
Phase 2: Minimal Execution Orchestration
  cmd-vpp-work-ljh + phase skills + human gate + decision evidence + JSONL telemetry
       ↓
Phase 3: Engineering Execution Expansion
  design/implementation/review adapters, dependency checks, approval UX
       ↓
Phase 4: Measurement and Improvement
  dashboards, ROI evaluation, calibration, skill feedback loop
       ↓
Phase 5: External Operations
  release/SRE, migration, Jira/Confluence/GitHub, deployment controls
```

## Components and Interfaces

### 1. PRD SSoT

Location: `docs/agent/prd/{slug}.md`

The PRD owns requirement meaning and lifecycle state. Each requirement has a
unique ID and one of these states:

```text
proposed | specified | ready | in_progress | implemented | verified
deferred | rejected | blocked
```

Required fields:

```markdown
### FR-001: Requirement title
- Status: ready
- Priority: P0
- Acceptance Criteria:
  - [ ] measurable criterion
- Dependencies: REQ-002
```

### 2. Traceability Index

Location: `docs/agent/traceability/{slug}.tsv`

The TSV is an index, not a second source of truth:

```text
requirement_id  status  design  code  test  verification
FR-001          verified docs/... src/... tests/... command or evidence
```

Validation is state-aware:

| PRD state | Design | Code | Test | Verification |
|---|---:|---:|---:|---:|
| proposed/specifed | required | optional | optional | optional |
| ready/in_progress | required | optional | required | optional |
| implemented | required | required | required | required |
| verified | required | required | required | required |
| deferred/rejected | required rationale | not required | not required | decision evidence |
| blocked | required blocker | not required | not required | blocker evidence |

### 3. Decision Evidence

The Decision Engine emits one JSON object per decision:

```json
{
  "decision_id": "dec-20261017-0001",
  "selected_action": "HUMAN_APPROVAL",
  "risk_level": "high",
  "uncertainty_level": "medium",
  "affected_requirements": ["SEC-001"],
  "applicable_policy_rules": ["security-sensitive", "no-implicit-approval"],
  "evidence_references": ["docs/agent/prd/auth.md#SEC-001"],
  "assumptions": [],
  "unresolved_questions": [],
  "human_approval_required": true,
  "next_action": "request-scoped-approval"
}
```

### 4. LLM Judge Interface

The Judge is an untrusted recommendation input. It does not execute tools or
approve policy exceptions.

```json
{
  "recommended_action": "AUTO_EXECUTE|RESEARCH_REQUIRED|SPEC_QUESTION|HUMAN_APPROVAL|BLOCKED",
  "risk_level": "low|medium|high|critical",
  "uncertainty_level": "low|medium|high",
  "repository_researchable": true,
  "required_questions": [],
  "assumptions": [],
  "evidence_references": []
}
```

### 5. Deterministic Policy Engine

Policy inputs include the request, explicit risk signals, PRD presence, approval
record, approval scope digest, and policy-engine health. Mandatory rules:

- policy error or missing mandatory decision fields → `BLOCKED`
- explicit denial or policy violation → `BLOCKED`
- deployment, destructive change, migration, security-sensitive, external
  resource, or money movement without valid scoped approval → `HUMAN_APPROVAL`
- approval scope digest mismatch → `HUMAN_APPROVAL`
- required unanswered question → `SPEC_QUESTION`
- repository-answerable uncertainty → `RESEARCH_REQUIRED`
- only low-risk, low-uncertainty, evidence-backed work may be
  `AUTO_EXECUTE`

### 6. Decision Router

The router combines Judge recommendation and policy result using this priority:

```text
BLOCKED > HUMAN_APPROVAL > SPEC_QUESTION > RESEARCH_REQUIRED > AUTO_EXECUTE
```

The router never downgrades a deterministic policy result because the LLM
recommended a safer action.

### 7. Telemetry JSONL

Location: `docs/agent/telemetry/decisions.jsonl` by default.

The minimum event schema is append-only and excludes prompts, secrets, and
chain-of-thought:

```json
{
  "event_version": 1,
  "event_type": "decision",
  "timestamp": "2026-10-17T12:00:00Z",
  "decision_id": "dec-20261017-0001",
  "selected_action": "RESEARCH_REQUIRED",
  "risk_level": "medium",
  "uncertainty_level": "medium",
  "route": "standard",
  "provider": "codex",
  "workflow_names": ["cmd-vpp-work-ljh", "skl-pre-research-ljh"],
  "human_approval_required": false,
  "evidence_count": 2,
  "result": "selected"
}
```

## Phase Contracts

### Phase 0 — Contract and Evidence Foundation

Exit gate: PRD state and traceability index are parseable; state-aware gate
passes or returns actionable failures; no requirement can be silently omitted.

### Phase 1 — Decision Engine

Exit gate: policy precedence, malformed input, missing approval, denial, scope
change, uncertainty, and Judge disagreement are deterministically tested.

### Phase 2 — Minimal Orchestration

Exit gate: route output includes decision evidence, complex/destructive/security/
migration tasks fail closed without approval, and one telemetry event is safely
written without sensitive prompt content.

### Phase 3 — Engineering Execution Expansion

Design only in the current scope. Requires PRD, design, dependency strategy,
acceptance criteria, and the `skl-mid-impl-ljh`/`skl-mid-review-ljh` capability
contracts before implementation work begins.

### Phase 4 — Measurement and Improvement

Design only in the current scope. Requires telemetry baselines, metric
definitions, retention policy, and a Skill evaluation dataset.

### Phase 5 — External Operations

Design only in the current scope. Requires release, migration, rollback,
external-system permissions, and incident ownership contracts.

## Non-goals in the Current Change

- No automatic deployment, merge, push, migration, or external resource change.
- No external database, dashboard, or MCP dependency.
- No LLM model optimization, threshold tuning, or chain-of-thought storage.
- No implementation of Phase 3–5 product capabilities.
