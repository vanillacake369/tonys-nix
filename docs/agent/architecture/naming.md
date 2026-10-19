# Agent Surface Naming Contract

## Purpose

This contract separates user-facing entrypoints from reusable agent
capabilities. It keeps the public surface small while allowing the repository
to absorb team guidance without exporting every internal workflow as a
command.

## Namespaces

| Prefix | Meaning | Invocation | Mutation authority |
|---|---|---|---|
| `cmd-*` | Explicit user-facing command | User/provider command surface | May request mutation, but must pass deterministic gates |
| `skl-*-ljh` | Project-owned lifecycle skill | Automatic selection or workflow delegation | No implicit external mutation |
| `skl-vpp-*-ljh` | VPP team-guideline source/adaptation skill | Internal reference or delegated capability | Inherits the enclosing workflow policy |

`ljh` identifies this repository's composition and policy. `vpp` identifies
the source lineage of absorbed team guidance. The suffix is metadata, not an
authority boundary; permissions still come from the role and policy contracts.

## Target public commands

The target public command surface is intentionally limited to four stable
entrypoints:

| Command | Primary responsibility |
|---|---|
| `cmd-vpp-work-ljh` | Route a task through risk, uncertainty, phase, and approval policy |
| `cmd-vpp-comment-ljh` | Produce scoped code comments and change explanations |
| `cmd-vpp-handoff-ljh` | Produce a durable handoff and operational context |
| `cmd-vpp-ship-ljh` | Prepare an explicitly approved release or external operation |

The command surface is a facade. It must not expose every design, review, or
provider-specific capability as a separate command.

The migration is implemented: provider adapters expose the four commands above
and the existing six canonical workflow IDs remain only in the legacy registry.
They are compatibility identifiers, not public command entrypoints, and must
not be expanded with new public commands.

## Project lifecycle skills

| Skill | Responsibility |
|---|---|
| `skl-pre-prd-ljh` | Clarification, domain terms, acceptance criteria, and PRD synthesis |
| `skl-pre-research-ljh` | Repository archaeology, technology research, and project bootstrap |
| `skl-pre-adr-ljh` | Independent strategies, cross-validation, conflict handling, and ADR |
| `skl-mid-impl-ljh` | TDD, code/infra design, implementation, refactoring, and debugging |
| `skl-mid-review-ljh` | Security, code, evidence, and independent review |
| `skl-mid-perf-ljh` | Measurement, bottleneck analysis, and performance improvement |
| `skl-post-ship-ljh` | Release preparation, approval scope, rollback, and observation planning |
| `skl-post-docs-ljh` | Documentation, handoff, runbook, and issue artifacts |
| `skl-phase-route-ljh` | Deterministic route selection and workflow composition |
| `skl-phase-gate-ljh` | Human approval, policy enforcement, and fail-closed behavior |
| `skl-phase-trace-ljh` | Traceability, evidence, telemetry, retry, and Git lifecycle checks |

These skills are capabilities, not additional public commands. A skill may
compose other skills, but it must preserve the enclosing role permissions and
approval requirements.

## VPP absorption

Team guidance is absorbed by capability bundle rather than copied into a
second public command tree:

| Source | Adapted location |
|---|---|
| `clarify`, `grill-with-docs`, `to-prd` | `skl-pre-prd-ljh` |
| repository archaeology and research guidance | `skl-pre-research-ljh` |
| ADR format and strategy review guidance | `skl-pre-adr-ljh` |
| `code-safety-guardrail` | `skl-mid-impl-ljh` |
| `code-review` and security review guidance | `skl-mid-review-ljh` |
| `ship` | `skl-post-ship-ljh` and `cmd-vpp-ship-ljh` |
| `handoff` | `skl-post-docs-ljh` and `cmd-vpp-handoff-ljh` |

The original canonical IDs remain available during migration. Display names
may use the new namespace, but traceability, telemetry, and ADR references do
not change until a separate migration decision is accepted.

## Classification rules

Use a skill when the work is reusable, contextual, read-only, design-oriented,
or produces evidence/documentation. Use a command when the user must explicitly
start the operation, the operation changes repository or external state, or a
Human Gate must be presented.

`LLM Judge` and `Review Gate` remain advisory regardless of the name or surface
through which they are invoked. Only deterministic policy and execution gates
can authorize execution.
