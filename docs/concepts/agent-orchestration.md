# Agent Orchestration Concepts

This page explains the multi-provider model at a conceptual level — why three providers, how they coordinate, how policy is encoded, and how reasoning modes differ. For configuration details and option references, see [Agents: Orchestration](../agents/overview.md) and [Agent Policy Contract](../architecture/agent-policy-contract.md).

## Why Three Providers

Using three AI providers is not redundancy. Each has a distinct strength that the others lack.

**Claude Code** is optimized for orchestration. It handles multi-step tool use, maintains state across a long conversation, and is designed to operate in an agentic loop where it plans, executes, observes, and replans. It is the natural primary interface for a developer session.

**Gemini CLI** has a large context window and web access, which makes it effective for research-heavy tasks: exploring an unfamiliar API, surveying the state of an ecosystem, auditing a design for blind spots it might share with the model that produced it. Crucially, Gemini and Claude are from different model families. When Claude has a design blind spot — an assumption it makes without recognizing it as an assumption — Gemini is more likely to catch it precisely because it was trained differently.

**Codex** provides independent verification through a third model family. Logic checks, algorithm reviews, and security analysis benefit from a model that approaches the code without any of the context or assumptions that accumulated during Claude's implementation session. The verification is meaningful because it is independent.

The three-provider model is a cross-checking architecture, not a cost-spreading one.

## The Orchestrator Pattern

Claude Code is the primary interface. The developer interacts with Claude; Claude delegates to Gemini and Codex. The delegation is structured, not ad hoc.

When Claude needs a strategy reviewed before proceeding, it does not call Gemini directly. Instead, the `strategy-lint` hook fires at `PreToolUse` time and checks whether a Gemini review file exists at the expected path. If it does not, the tool call is blocked. Claude must invoke Gemini, wait for the result, and ensure the review file is written before it can proceed. The orchestration is enforced by the hook pipeline, not left to Claude's discretion.

Inter-provider communication happens through three mechanisms:

**FIFO pipes for async results.** When Claude initiates a strategy review, it writes a task description to a named pipe in `/tmp/agent-handshake/gemini/`. Gemini reads from the pipe asynchronously, runs the analysis, and writes the result to `/tmp/agent-handshake/gemini/results/`. Claude polls for the result file. The three supported task types are `strategy-review`, `blindspot-audit`, and `impact-analysis`. This design keeps the providers decoupled: neither Gemini nor Codex needs to know it is being called from within a Claude session.

**Shared state files for phase coordination.** The phase state for each session is stored as a flat file in `/tmp/agent-policy/phases/<provider>/<session-id>`. The `phase-gate` hook reads this file before allowing any Write or Edit call. A separate `<session-id>.approved` file signals that the strategy has been reviewed and the session is cleared to enter the execution phase. These files are the shared clock that keeps Claude from proceeding past the strategy gate prematurely.

**`agent-notify.sh` for completion signals.** Each provider fires `agent-notify.sh <provider>` on session end. On macOS this triggers a system notification. The same script is used for human escalation: when the `escalation-gate` hook detects three consecutive failures, it calls `agent-notify.sh human` with a reason and summary, signaling that the situation requires a human decision rather than another retry.

## Policy as Code

The conventional approach to agent guardrails is prompt engineering: include a `CLAUDE.md` that says "always produce a strategy document before writing code" and trust the model to comply. This approach is not wrong — clear instructions do influence behavior — but it is not sufficient for high-stakes guardrails where the cost of a miss is significant.

This repository's approach is to encode guardrails as Nix module options that generate hook scripts. The distinction matters:

- A prompt instruction is evaluated by the model on each turn. The model can decide to proceed anyway, especially under time pressure or in a long context where early instructions have faded.
- A hook script runs at the shell level on every matching tool call. It reads the event payload, checks preconditions, and exits with a code that either allows, retries, or blocks the call — regardless of what the model decided to do.

The phase gate, path guard, strategy lint, and live oracle are all implemented as hooks. They do not ask for compliance. They enforce it at the process boundary.

The Nix layer adds a second property: contract coherence. Before any hook script is written, `nix build` validates that the configuration is internally consistent. A phase gate that would silently pass everything (because `gatedTools` is empty) is caught at build time. A strategy lint requirement that has no peer review provider assigned is caught at build time. The invariants are expressed once, in `lib/agent-policy/assertions.nix`, and checked on every build.

## Reasoning Separation

Not all providers need to show their reasoning in the terminal, and not all reasoning is equally useful to see.

**`silent` (Claude)** — Claude's chain-of-thought is written to `/tmp/agent-traces/claude/<session>.log` but is not displayed in the conversation. Only lines that begin with structured markers (`DECISION:`, `ACTION:`, `RESULT:`, `OUTPUT:`) or match the `^\[` pattern are emitted to the terminal. This keeps the conversation focused on decisions and actions, not on the model's intermediate reasoning steps. The traces are available for debugging if needed.

**`verbose` (Gemini)** — Gemini's full output passes through unchanged. This is intentional: when Gemini is running a blindspot audit or impact analysis, the reasoning process is the output. The developer needs to see the chain of inference to evaluate whether the critique is valid, not just the final verdict.

**`log-only` (Codex)** — Codex's tool output is appended to trace files at `/tmp/agent-traces/codex/` and nothing is shown in the terminal. Codex runs verification tasks in the background; its output is an audit trail, not a conversation. The developer reviews the trace when a verification fails, not on every run.

These modes are set as the `reasoning.mode` option in each provider's contract declaration. The `reasoning-trace` mixin generates a `PostToolUse` hook that implements the filtering and logging behavior for each mode. `verbose` mode produces no hook — it is a no-op passthrough.

## Provider Summary

| Provider | Role | Reasoning Mode | Policy Capabilities |
|---|---|---|---|
| Claude | Orchestrator | `silent` | phase-gate, path-guard, strategy-lint, live-oracle, reasoning-trace |
| Gemini | Researcher / Critic | `verbose` | path-guard, async-handshake |
| Codex | Logic Verifier | `log-only` | path-guard, reasoning-trace |

The difference in capability scope is intentional. Claude carries the most policy weight because it is the primary execution surface — it is the provider that writes files, runs commands, and makes decisions with real side effects. Gemini and Codex have narrower policy profiles because their roles are advisory: they produce text that Claude (or the developer) evaluates, rather than directly mutating the system.
