# Provider Mapping

This file records the equivalence rules between provider-neutral contracts and
provider-specific exports. It intentionally avoids mirroring the current file
layout.

## Principles

- Shared policy must reach every enabled provider in that provider's native
  surface.
- Provider-specific mechanics may differ, but user-visible safety and workflow
  behavior should remain equivalent.
- Unsupported provider capabilities must be documented explicitly instead of
  silently omitted.
- Generated or exported artifacts should be validated at the boundary where they
  become provider-native.

## Required Equivalence

- Sensitive data rules are represented by each provider's permissions, hooks, or
  deterministic guards.
- Approval-sensitive actions require an approval path wherever the provider can
  perform the action.
- Forbidden actions have deterministic block behavior and cannot rely on model
  judgment alone.
- Workflow guidance is available through the provider's normal command, skill,
  context, or instruction surface.
- Telemetry fields that are emitted by any provider map to the portable
  telemetry vocabulary or are documented as provider-specific metadata.
