# Eval Results

Store eval result artifacts here when an eval runner exists.

Each result must conform to `modules/agents/specs/schemas/eval-result.schema.json`.

Recommended path:

```text
modules/agents/specs/evals/results/<dataset>/<run-id>/<case-id>.json
```

Do not store raw prompts, tool outputs, secrets, or private user data in eval results.
