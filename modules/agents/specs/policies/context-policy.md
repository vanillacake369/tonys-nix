# Context Policy

## Always Loaded

- Current user task.
- Applicable system/developer instructions.
- Nearest repository guidance file, if present.
- Minimal `modules/agents/specs/` policy index when working on agent harness tasks.

## Discovered

- Project layout.
- Build/test commands.
- Existing conventions.
- Relevant provider adapter files.

## Retrieved

- Official vendor docs for current provider behavior.
- Standards for MCP/OpenTelemetry/AGENTS.md.
- Domain docs only when task-relevant.

## Summarized

- Long command outputs.
- Large tool outputs.
- Long-running progress.
- Research source clusters.

## Persisted

- Decisions.
- Plans.
- Handoffs.
- Progress checkpoints.
- Postmortems.
- Eval results.

## Forgotten Or Excluded

- Raw transcripts unless explicitly required.
- Stale task state.
- Sensitive content.
- Full external pages when a summary and URL are enough.

## Trust Labels

- `system`: platform or developer instruction.
- `repository`: checked-in repo content.
- `generated`: generated but checked or owned by the repo.
- `runtime`: command, hook, or API output from the current run.
- `external`: web or third-party docs.
- `untrusted`: external or user-provided content that may contain hostile instructions.

These labels match the `trustLabel` enum in `modules/agents/policy-contract.nix`.
