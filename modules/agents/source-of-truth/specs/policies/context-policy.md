# Context Policy

## Always Loaded

- Current user task.
- Applicable system/developer instructions.
- Nearest repository guidance file, if present.
- Minimal agent-harness policy index when working on agent harness tasks.

## Discovered

- Project layout.
- Build/test commands.
- Existing conventions.
- Relevant provider export files.

## Retrieved

- Official vendor docs for current provider behavior.
- Standards for provider protocols, telemetry, and agent instruction files.
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

Provider exporters and hook assets should preserve these labels when they emit
or persist context evidence.
