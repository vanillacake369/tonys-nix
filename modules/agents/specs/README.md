# Agent Harness Specs

`modules/agents/` is the executable source of truth for this repository's agent harness:

- `policy-contract.nix` defines typed provider-neutral contracts.
- `policy-assertions.nix` validates contract invariants at build time.
- `policy-*.nix` mixins enforce policy through hooks.
- `providers/*/module.nix` adapts the contract to Claude, Codex, and Gemini.

For onboarding and change routing, start with `modules/agents/README.md`.

This `specs/` directory contains portable declarative inputs and documentation-shaped contracts that should either map to `agentPolicy.*` or be validated against it.

## Mapping

| Spec area | Path | Executable contract target |
| --------- | ---- | -------------------------- |
| Policies | `policies/` | `agentPolicy.global`, `agentPolicy.workflow`, provider policy options |
| Tools | `tools/tool-policy.yml` | `agentPolicy.tools`, provider tool adapters, hook guards |
| Telemetry | `telemetry/` | `agentPolicy.telemetry`, AgentOpsEvent JSONL, OTLP bridge |
| Evals | `evals/` | future eval runner inputs and result schemas |
| Memory | `memory/` | handoff/progress/postmortem artifacts |
| Workflows | `workflows/` | `agentPolicy.registry.workflows` |
| Capabilities | `agents/capability-map.md` | `agentPolicy.registry.capabilities` |
| Schemas | `schemas/` | validation inputs for specs and artifacts |

## Rule

If a spec and Nix contract disagree, the Nix contract is the current executable authority. Fix the spec or add an explicit contract migration; do not let both remain divergent.
