# Project-local Engineering System

This directory is the project-local artifact root for the Codex Engineering
System. It is separate from the provider home directory `~/.codex/`, which
contains generated Codex agents and skills.

## Canonical artifacts

- `prd/`: Markdown PRD SSoT
- `adr/`: accepted technical decisions
- `architecture/`: architecture and phase contracts
- `architecture/naming.md`: command, skill, and VPP absorption naming contract
- `testing/`: test specifications and verification plans
- `traceability/requirements.tsv`: requirement-to-artifact index
- `telemetry/decisions.jsonl`: minimum decision evidence
- `memory/`: project-isolated session, daily, and durable memory
- `runbooks/`: future operational handoffs
- `agent-config.toml`: project-local path and workflow configuration
- `project-policy.json`: layered policy input validated before execution

Provider-neutral behavioral rules remain in `tonys-agent-harness/nix/agents/AGENTS.md`; this
directory contains project artifacts and project-specific policy only.
