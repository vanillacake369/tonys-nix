# Adapter Mapping

This file records how portable specs map to current provider implementations.

| Canonical area | Claude surface | Codex surface | Nix contract | Current status |
| -------------- | -------------- | ------------- | ------------ | -------------- |
| Stable policy | shared `AGENTS.md` guide, generated hooks | generated context, rules, permissions | `agentPolicy.providers`, `agentPolicy.global` | partially mapped |
| Sensitive paths | path guard hooks | permission profiles | `agentPolicy.global.sensitivePatterns` | Nix is authoritative |
| Workflow phases | generated Claude hooks | generated Codex hooks | `agentPolicy.registry.workflows`, `agentPolicy.workflow` | mapped through hook adapters |
| Tool policy | Claude native tools plus hooks | Codex tools plus rules/permissions | `agentPolicy.tools`, future tool catalog mapping | incomplete |
| Telemetry | hook JSONL/logs | hook JSONL/logs | `agentPolicy.telemetry` | JSONL exists; span bridge incomplete |
| Skills | `modules/agents/providers/claude/commands`, future skills | generated Codex skills | `providers/codex/bindings.nix`, `adapters/workflows.nix` | generated for current roles/workflows |
| Evals | hook tests, Nix checks | hook tests, Nix checks | `tests/guard.test.nix`, `tests/hooks` | baseline harness evals incomplete |

## Required Equivalence Checks

- Every sensitive pattern in `agentPolicy.global.sensitivePatterns` must be represented in provider deny rules or hooks.
- Every R3 or R4-approval tool/action must have approval behavior in each enabled provider.
- Every R4-forbidden tool/action must have deterministic block behavior in each enabled provider.
- Every workflow phase gate in `agentPolicy.registry.workflows` must be representable by provider hooks or documented as unsupported.
- Every emitted AgentOpsEvent field must map to the telemetry span catalog or be documented as vendor/custom metadata.
