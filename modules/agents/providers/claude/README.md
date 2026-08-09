# Claude Code Configuration

This provider exports Claude Code assets from the shared agent harness.

## Role

- Publish provider-neutral instructions to Claude's native context surface.
- Keep Claude-specific commands, hooks, agents, and skills in provider-owned
  assets.
- Merge generated settings with mutable runtime state without replacing user
  state unnecessarily.

## Boundary

Shared behavior belongs in the source of truth. This provider may adapt that
behavior to Claude's file formats, but it should not fork the behavioral policy.

## Sync Model

Home Manager exports static assets and merges dynamic settings. Runtime state
should be preserved where possible, because provider CLIs often write local
trust, project, or history data.

## Changing Claude Support

Prefer changing shared policy first when the behavior should apply across
providers. Change Claude-owned assets only for Claude-native presentation,
compatibility, or ergonomics.
