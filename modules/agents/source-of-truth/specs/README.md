# Agent Harness Specs

This directory keeps portable contracts for the agent harness. It is not a
second implementation. It records the stable ideas that should survive provider
renames, option churn, and file movement.

## Role

- Capture provider-neutral policy in prose, schemas, or small declarative data.
- Keep memory, telemetry, workflow, tool, and capability contracts portable.
- Give tests and future exporters something stable to validate against.
- Avoid duplicating implementation details that are likely to move.

## Boundaries

Specs may name concepts and required behaviors. They should not prescribe
temporary file layouts, generated variable names, or provider-specific plumbing
unless that detail is itself part of the public contract.

When a spec and executable behavior disagree, treat the executable behavior as
the current fact and make an explicit decision: migrate the implementation or
update the stale spec.

## Maintenance

Keep this directory alive by favoring durable categories over inventories. A
good spec explains what must remain true; it does not try to mirror every
current filename.
