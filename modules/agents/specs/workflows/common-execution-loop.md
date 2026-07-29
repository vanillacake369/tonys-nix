# Common Execution Loop

## Base Loop

```text
Observe
-> Classify
-> Gather Context
-> Plan if needed
-> Act
-> Observe Result
-> Verify
-> Replan or Finish
```

## High-Risk Loop

```text
Explore
-> Specify
-> Plan
-> Risk Review
-> Execute Small Step
-> Deterministic Validation
-> Review
-> Repeat
-> Final Evaluation
-> Postmortem
```

## Stop Rules

- Acceptance criteria pass.
- Deterministic tests/checks pass.
- No unresolved high-severity findings remain.
- Evaluation target reached.
- Iteration budget exhausted.
- No measurable improvement after the configured budget.
