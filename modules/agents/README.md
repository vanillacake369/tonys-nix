# Agent Harness Module Map

`modules/agents/` is the executable source of truth for the local agent
harness. Keep the public option namespace stable under `agentPolicy.*`; move
implementation details only when the ownership boundary becomes clearer.

## Read This First

Start from the change you need to make:

| Change | Primary files | Validation |
| --- | --- | --- |
| Add or change an MCP server | `agents-mcp.nix`, `adapters/mcp.nix` only if the provider shape changes | `nix build .#checks.$(nix eval --impure --raw --expr builtins.currentSystem).guard-tests --no-link` |
| Add a provider | `providers/<name>/module.nix`, `adapters/hooks.nix`, `adapters/mcp.nix`, `runtime/provider-settings.nix` if the settings format is new | guard tests plus focused Nix eval |
| Change a provider role or capability | `providers/<name>/module.nix` | focused Nix eval |
| Add a policy capability | `policy-<capability>.nix`, `policy-assembler.nix`, `policy-assertions.nix` if an invariant is required | guard tests and hook tests |
| Change hook format conversion | `adapters/hooks.nix` | guard tests |
| Change workflow or skill bindings | `adapters/workflows.nix`, `skills/`, provider artifact source files | guard tests |
| Change Codex generated agents or skills | `providers/codex/bindings.nix` | guard tests |
| Change mutable config sync behavior | `runtime/mutable-settings-sync.nix`, `runtime/provider-settings.nix` | focused Nix eval and activation review |
| Change portable specs | `specs/` | JSON/YAML validation and guard tests |

## Ownership Boundaries

| Area | Responsibility | May depend on | Must not do |
| --- | --- | --- | --- |
| `policy-contract.nix` | Typed provider-neutral option contract | Nix `lib.types` | Reference provider config paths |
| `policy-assertions.nix` | Build-time invariants over `agentPolicy.*` | Contract and registry values | Render provider settings |
| `policy-*.nix` | Feature-oriented policy mixins that emit canonical hooks or state | `agentPolicy.*` values | Know provider-native settings formats |
| `policy-agentops-registry.nix` | Capabilities, executors, workflows, context sources | Contract types | Emit runtime hook formats |
| `adapters/` | Pure provider format conversion | Canonical Nix data | Decide policy |
| `runtime/` | Assembly, generated settings files, mutable config sync | Adapters and assembled policy hooks | Own provider-specific assets |
| `providers/` | Provider modules and static provider artifacts | Runtime helpers and shared guide | Redefine shared behavior |
| `skills/` | Shared reusable skill directories consumed by provider adapters | Shared guide and local references | Depend on provider-native config formats |
| `shared/` | Human-edited provider-neutral agent guide | None | Fork provider-specific policy |
| `specs/` | Portable schemas, eval inputs, and minimal reference text | Executable contract as authority | Override Nix behavior silently |

## Dependency Direction

The intended direction is:

```text
policy-contract.nix <- policy-*.nix <- policy-assembler.nix
policy-assembler.nix -> adapters/hooks.nix -> runtime/provider-settings.nix
providers/*/module.nix -> runtime/provider-settings.nix
providers/*/module.nix -> adapters/workflows.nix
```

Provider modules adapt the contract to a concrete CLI. They should stay thin:
declare provider capability values, export provider assets, and call runtime
settings helpers.

## Complexity Indicators

Use these indicators before and after structural changes:

| Indicator | What to check | Good direction |
| --- | --- | --- |
| Change locality | Files touched for common changes | Smaller, predictable edit sets |
| Responsibility mixing | One file changing for unrelated reasons | Fewer mixed responsibilities |
| Provider leakage | Provider names in provider-neutral layers | Only inside adapters, providers, or explicit registry data |
| Spec-to-code drift | Stale paths in specs/tests | Zero stale canonical paths |
| Import clarity | Entry point to generated artifact trace | Clear path without hidden ownership jumps |
| Root navigation cost | Top-level files a newcomer must classify | Lower, but not by hiding policy mixins |
| Validation cost | Focused checks for a change type | Clear command per change type |

Do not optimize raw file count, line count, or directory depth by themselves.
Those are review signals, not design goals.

## Current Refactor Rule

Keep `policy-*.nix` files as feature-oriented mixins unless a file has multiple
real reasons to change. The main hotspots for future responsibility splitting
are:

- `policy-contract.nix`: separates many option families in one file.
- `policy-phase-gate.nix`: still combines Nix code generation, shell runtime,
  marker validation, and mutation detection. AgentOps event/OTLP emission is
  isolated in `runtime/agentops-event.nix` so schema drift has a single runtime
  owner.

Move those only with focused tests and before/after complexity measurements.
