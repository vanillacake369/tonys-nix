# Execution Policy

## Task Classification

| Tier | Use when | Required process | Stop condition |
| ---- | -------- | ---------------- | -------------- |
| T0 | Direct deterministic action | Execute command or read file | Output collected |
| T1 | Small bounded local task | Lightweight intent and validation | Acceptance criteria met |
| T2 | Multi-file implementation | Short plan, focused edits, deterministic validation | Tests/checks pass |
| T3 | Ambiguous research or architecture | Research, audit, ADR, review | Decision artifact complete |
| T4 | Long-running optimization | Baseline, one change, eval, compare | Target met or budget exhausted |

## Escalation Order

```text
Deterministic script
-> Single tool call
-> Single agent
-> Agent + skill
-> Agent + evaluator
-> Planner / Executor
-> Parallel subagents
-> Persistent autonomous loop
```

## Execution Loop

```text
Observe
-> Classify
-> Gather context
-> Plan if needed
-> Act
-> Observe result
-> Verify
-> Replan or finish
```

## Rules

- Do not create multi-agent topology when a deterministic script or single agent is enough.
- Mutating actions require validation evidence.
- Long-running work requires progress and handoff artifacts.
- Never continue until "perfect"; use explicit success criteria and budgets.
