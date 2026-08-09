# Agent Provider Exporter

This module owns the local agent harness. It should stay small, readable, and
boring: one provider-neutral source, one set of outporters, and thin provider
modules.

## Shape

The top-level directories are named by responsibility:

- `source-of-truth/` holds durable, provider-neutral policy, specs, and shared
  source data.
- `outporters/` converts shared data into provider-native output shapes.
- `providers/` owns provider-specific assets and the final Home Manager exports.

Provider-neutral behavior belongs in the source of truth. Provider quirks belong
in providers or outporters. Tests should verify behavior and output shape, not
private implementation topology.

## Ownership Boundaries

- Source material describes intent and stable contracts. It should avoid
  provider-native syntax unless the syntax itself is the contract.
- Outporters are pure translation code. They should not decide policy.
- Provider modules are integration edges. They should not redefine shared
  behavior.
- Specs are portable reference material. When executable behavior and specs
  disagree, either migrate the implementation deliberately or update the stale
  spec.

## Dependency Direction

Keep dependencies flowing outward:

```text
source of truth -> outporters -> providers
```

Reverse dependencies are a design smell. A provider may adapt shared policy, but
shared policy must not depend on provider implementation details.

## Complexity Indicators

Use these indicators before and after structural changes:

| Indicator | What to check | Good direction |
| --- | --- | --- |
| Change locality | Files touched for common changes | Smaller, predictable edit sets |
| Responsibility mixing | One file changing for unrelated reasons | Fewer mixed responsibilities |
| Provider leakage | Provider names in provider-neutral layers | Only where provider behavior is being translated or exported |
| Spec-to-code drift | Stale reference material | Specs track the executable contract |
| Import clarity | Entry point to generated artifact trace | Clear path without hidden ownership jumps |
| Navigation cost | Concepts a newcomer must classify | Lower, without hiding provider behavior |
| Validation cost | Checks required for confidence | Focused first, broader when blast radius grows |

Do not optimize raw file count, line count, or directory depth by themselves.
Those are review signals, not design goals.
