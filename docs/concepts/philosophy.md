# Philosophy: Why This Exists

## The Problem

Dotfiles repositories solve half the problem. They manage the environment — packages, shell configuration, editor plugins, keymaps — and they do it well. Given a fresh machine and a working Nix installation, `just apply` produces a deterministic system that matches every other machine running the same configuration. That part works.

The other half of the problem is the agents. When Claude Code, Gemini CLI, and Codex each need guardrails — phase gates that block file mutations until a strategy is approved, path guards that prevent access to credentials, escalation policies that call a human when retries are exhausted — those rules traditionally live in Markdown files. A `CLAUDE.md` instructs the model to follow a process. An `AGENTS.md` describes role boundaries. These files work until they do not.

The failure mode is silent. A hook script is accidentally excluded from a provider's settings. A required `pre-mortem` section is missing from a strategy document but the model proceeds anyway because nothing checked. A new provider is added to the configuration and inherits no guardrails because the setup is manual and incomplete. The developer only discovers the gap when the situation it was designed to handle occurs — and by then, the incorrect action has already been taken.

## The Solution

Encode the guardrails as Nix modules. Make the rules structural rather than advisory.

The agent policy contract system in `lib/agent-policy/` translates behavioral requirements into typed Nix options. Every provider that participates in the orchestration declares its capabilities against a shared interface defined in `contract.nix`. The Nix module system then validates those declarations at build time through `config.assertions` in `assertions.nix`. If any contract invariant is violated, `nix build` fails before any hook script is written to any provider's settings file.

Concretely, this means:

- A provider that enables `strategyLint` without setting `peerReviewProvider` is a **build error**, not a runtime omission.
- A phase gate configured with an empty `gatedTools` list is a **build error**, not a hook that silently allows everything through.
- A provider without a `hooks.format` declaration is a **build error**, not a config file that fails to parse at startup.
- An `oracle.enabled = true` with no `healthChecks` defined is a **build error**, not a check that never runs.

The same `nix build` that produces your home-manager activation also validates that the agent policy contract is coherent. The environment and its guardrails are deployed atomically or not at all.

## Design Principles

### 1. Declarative over imperative

Provider policies are Nix option values, not shell scripts scattered across dotfiles. The policy for Claude Code lives in `modules/agents/claude.nix` as a structured attrset. It is readable, diffable, and auditable. When you change a policy — say, adding `NotebookEdit` to the list of gated tools — you change one value and run `just apply`. The corresponding hook script is regenerated automatically.

The alternative is manually editing a shell script, making sure it handles the right exit codes, and remembering to copy it to the right path. That approach invites drift.

### 2. Build-time validation over runtime hope

The standard approach to agent configuration is documentation: write down the rules and trust the model to follow them. This repository treats that as a necessary but insufficient layer. Documentation explains intent; build-time assertions enforce structure.

Nix's `config.assertions` mechanism was designed for exactly this purpose: catching configuration errors before they reach a running system. The agent policy contract borrows this mechanism directly. A misconfigured provider produces a build failure with a message pointing at the exact violated invariant, not a mysterious behavior at runtime.

### 3. Composition over inheritance

The six policy capabilities — reasoning trace, async handshake, live oracle, phase gate, path guard, and strategy lint — are independent mixins. Each lives in its own file in `lib/agent-policy/mixins/`. A provider activates the capabilities it needs by setting the corresponding options.

Claude uses five mixins. Gemini uses two. Codex uses two, a different two. There is no base class, no inheritance hierarchy, and no requirement that every provider implement every capability. Adding a new provider means declaring which capabilities it needs. Adding a new capability means writing a single mixin that reads from `config.agentPolicy.providers` and writes to `config.agentPolicy._hooks`. The Nix module system handles the wiring.

### 4. Single Source of Truth

Two cross-cutting concerns apply to all providers and are declared exactly once:

**MCP servers** are defined in `modules/agents/mcp.nix`. The `lib/mcp-adapters.nix` file transforms that single declaration into the format each provider expects: pass-through for Claude, `command + args` only for Gemini, TOML with an `enabled` flag for Codex. Adding a new MCP server means editing one file.

**Path guard patterns** are defined in `agentPolicy.global.sensitivePatterns`. Every enabled provider's path-guard hook is generated from this single list. There is no per-provider copy of `.env*` patterns to keep in sync.

### 5. Escape hatches exist

The contract-generated hooks coexist with hand-written hooks in `dotfiles/claude/hooks/`. The base settings in `dotfiles/claude/settings.json` define the static hooks; the policy system deep-merges generated hooks on top per event array during activation. Neither layer overrides the other.

This means migration is incremental. You can adopt the contract system for new capabilities while leaving existing hand-written hooks untouched. You can also run a provider with `enable = true` but with every policy option at its default (no phase gate, no strategy lint, no oracle), and the only generated hook will be the path guard for sensitive files. The contract does not impose a particular level of enforcement.

## What This Is Not

This is not a framework or library. There is no package to import, no API to program against. It is a personal configuration that demonstrates a pattern: using the Nix module system's type declarations, assertions, and IoC wiring to make agent guardrails structural.

The pattern is designed to be understood and adapted. If you want to adopt it, the relevant code is in `lib/agent-policy/` — roughly 400 lines across six files. Reading `contract.nix`, `assertions.nix`, and one mixin is enough to understand the shape of the whole system.

If you want to extend it — adding a new mixin, a new assertion, or a new provider format — the process is additive. No existing code needs to change. See [Agent Policy Contract](../architecture/agent-policy-contract.md#adding-a-new-mixin) for the step-by-step.
