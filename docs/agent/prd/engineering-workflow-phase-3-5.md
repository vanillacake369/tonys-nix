# PRD: Engineering Workflow Phases 3–5 — Design Only

This document specifies future phases only. It contains no implementation
authorization for the current change.

## Phase 3 — Engineering Execution Expansion

### Objective

Connect approved decisions to lifecycle skills for design, implementation,
test, review, and documentation while preserving provider-neutral policy and
one writer. Public commands remain facades rather than multiplying with each
specialist capability.

### Dependencies

- Phase 0 state-aware PRD and traceability gate
- Phase 1 Decision Engine policy precedence
- Phase 2 scoped human approval and decision evidence
- Codex/Kiro role and workflow projections
- Repository-specific build and test commands
- `docs/agent/architecture/naming.md` command/skill contract

### Design

```text
Decision Router
  → selected public command facade
  → lifecycle skill plan
  → read-only research/design roles
  → one implementation owner
  → test/security/independent review
  → traceability update
  → evidence gate
```

Execution adapters must consume a frozen plan, receive only the permissions
required by their role, and return structured artifacts. A new approval is
required if the implementation scope, target environment, risk category, or
affected requirements change materially.

### Acceptance Criteria

- [ ] Approved plans produce a deterministic role/dependency execution plan.
- [ ] Parallel roles are read-only and cannot write the same repository.
- [ ] Exactly one writer owns implementation mutations.
- [ ] Security-sensitive changes automatically include security review.
- [ ] Code, test, infrastructure, and documentation artifacts update the traceability index.
- [ ] Missing evidence prevents completion.
- [ ] Deployment, migration, push, merge, and external mutation remain separate approved operations.
- [ ] Specialist capabilities are invoked as `skl-*-ljh` skills and are not
  exported as additional public commands.

## Phase 4 — Measurement and Improvement

### Objective

Turn the minimum JSONL decision events into measurable quality, cost, and Skill
improvement feedback without allowing metrics to weaken policy.

### Dependencies

- Phase 2 telemetry schema and retention boundary
- Stable decision IDs and route/action vocabulary
- Phase 3 execution/review evidence
- A representative, privacy-safe evaluation fixture set
- Defined ownership for metric interpretation

### Design

```text
JSONL events → local aggregation → quality/cost metrics
             → Skill evaluation dataset → proposed improvement
             → independent validation → contract or prompt change
```

Metrics must distinguish model recommendation from policy decision and must not
store prompts, secrets, or chain-of-thought. Automatic threshold tuning is not
allowed until false-positive and false-negative baselines exist.

### Acceptance Criteria

- [ ] Dashboard metrics distinguish AUTO_EXECUTE, RESEARCH_REQUIRED, SPEC_QUESTION, HUMAN_APPROVAL, and BLOCKED.
- [ ] Cost, latency, retry, human-intervention, and review-defect metrics are defined.
- [ ] Skill changes have before/after evaluation evidence.
- [ ] Metric collection failure cannot bypass a policy gate.
- [ ] Retention, privacy, and deletion rules are documented.
- [ ] No automatic policy relaxation is driven solely by telemetry.

## Phase 5 — External Operations

### Objective

Add explicitly approved release, SRE, migration, and external-system skills and
commands without weakening the public command boundary.

### Dependencies

- Phase 3 execution and review adapters
- Phase 4 audit-quality telemetry
- Environment identity and scoped credentials
- Deployment/migration dry-run and rollback contracts
- Incident ownership, escalation, and runbook standards
- MCP integrations with least-privilege permissions

### Design

```text
approved release intent
  → cmd-vpp-ship-ljh
  → skl-post-ship-ljh
  → environment and scope verification
  → dry-run / migration plan
  → explicit approval
  → execute one external mutation
  → observe
  → rollback or close with evidence
```

External operations are never implied by a code implementation decision. Every
operation must identify target environment, affected resources, rollback,
operator, approval, and observation window.

### Acceptance Criteria

- [ ] Production deployment requires environment-specific approval.
- [ ] Data migration requires backup, dry-run, integrity check, and rollback plan.
- [ ] External MCP operations use least-privilege credentials and explicit targets.
- [ ] Push, merge, deployment, and resource mutation are individually auditable.
- [ ] Failed observation or missing rollback evidence blocks closure.
- [ ] Incident and post-deployment handoff artifacts are generated.

## Current Scope Boundary

Phases 3–5 are design artifacts only in this change. No execution adapter,
dashboard, external database, deployment, migration, push, merge, or MCP
mutation is implemented.
