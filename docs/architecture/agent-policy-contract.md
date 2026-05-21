# Agent Policy Contract System

The Agent Policy Contract system translates behavioral rules from `CLAUDE.md` into Nix module options that are validated at build time. Violations cause `nix build` to fail with a descriptive message before any hook script reaches a provider's settings file.

## Motivation

Text-based guardrails in `CLAUDE.md` work until they do not. A hook script might be missing, a required section might be skipped under time pressure, or a new provider might be added without implementing the full policy suite. These failures are silent: the developer only discovers the missing guardrail when the situation it was designed to handle occurs.

The contract system makes the same rules structural:

- **A missing peerReviewProvider is a build error**, not a runtime surprise.
- **An empty gatedTools list with enforcement enabled is a build error**, not a hook that silently passes everything.
- **A new provider without a hooks.format is a build error**, not a config file that fails to load.

The Nix module system already provides the infrastructure needed for this: option type declarations act as interfaces, provider modules act as implementations, and `config.assertions` act as contract validation.

## Pattern Mapping

| OOP / DDD Concept | Nix Module System Equivalent | Location |
|---|---|---|
| Contract / Interface | `mkOption` type declarations | `lib/agent-policy/contract.nix` |
| Implementation | Provider module sets `agentPolicy.providers.<name>` values | `modules/agents/<provider>.nix` |
| Assertion / Precondition | `config.assertions` — fails `nix build` on violation | `lib/agent-policy/assertions.nix` |
| Mixin / Trait | Module in `mixins/` that reads options and writes `_hooks` | `lib/agent-policy/mixins/` |
| IoC Container | Nix module system auto-wires option producers to consumers | `lib/agent-policy/policy.nix` |
| Adapter | Format conversion from canonical hooks to provider-native | `lib/agent-policy/hook-adapters.nix` |

## Contract Interface

`lib/agent-policy/contract.nix` defines a `providerModule` submodule with six option groups. Every provider that sets `agentPolicy.providers.<name>` must satisfy this type.

### (A) reasoning

Controls whether the agent's chain-of-thought is displayed, logged, or suppressed.

| Field | Type | Values | Default |
|---|---|---|---|
| `mode` | enum | `silent`, `verbose`, `log-only` | `"verbose"` |
| `traceDir` | string | filesystem path | `"/tmp/agent-traces"` |

`silent`: reasoning is written to `traceDir/<provider>/<session>.log`; only lines matching `^\[` or starting with `DECISION:`, `ACTION:`, `RESULT:`, `OUTPUT:` are emitted to the terminal.

`verbose`: full output passes through unchanged. No hook file is generated.

`log-only`: all tool output is appended to the trace log. Nothing is shown in the terminal.

### (B) async

Configures background task execution via FIFO pipes.

| Field | Type | Default |
|---|---|---|
| `enabled` | bool | `false` |
| `backgroundTasks` | list of string | `[]` |
| `handshakeProtocol` | enum: `poll`, `fifo`, `callback` | `"fifo"` |
| `fifoDir` | string | `"/tmp/agent-handshake"` |

When `enabled = true`, a named pipe is created in `fifoDir/<provider>/` for each entry in `backgroundTasks`. A `PostToolUse` hook captures completion records to `fifoDir/<provider>/results/`.

### (D) oracle

Runs shell commands after file mutations to verify the environment remains healthy.

| Field | Type | Default |
|---|---|---|
| `enabled` | bool | `false` |
| `healthChecks` | list of `{ command, pattern, timeout }` | `[]` |
| `streamAnalysis` | bool | `false` |

Each health check runs only when the mutated file path matches `pattern` (a regex). If `streamAnalysis = true`, failed checks are re-executed with their output captured and printed inline.

### (E) phases

Enforces the RESEARCH → STRATEGY → EXECUTION state machine by blocking certain tools until a complexity classification and approval exist.

| Field | Type | Default |
|---|---|---|
| `enforced` | bool | `false` |
| `stateDir` | string | `"/tmp/agent-phases"` |
| `gatedTools` | list of string | `["Write" "Edit"]` |

State is stored in flat files at `agentPolicy.global.stateRoot/phases/<provider>/<session-id>`. The first character of this file holds the complexity level (`S`, `M`, or `L`). An `<session-id>.approved` file signals strategy approval.

### (F) strategyLint

Validates that strategy documents contain required sections and that a peer review exists before allowing execution.

| Field | Type | Default |
|---|---|---|
| `enabled` | bool | `false` |
| `requiredSections` | list of string | `[]` |
| `peerReviewProvider` | null or string | `null` |
| `strategyPath` | string | `"/tmp/agent-strategy"` |

When `peerReviewProvider` is set, the mixin also checks for `<strategyPath>/<session-id>-review.md`. If that file is absent, mutation tools are blocked.

### hooks (format metadata)

Describes how to format and where to write the assembled hooks.

| Field | Type | Required |
|---|---|---|
| `format` | enum: `claude`, `gemini`, `codex` | yes |
| `outputPath` | string | yes |
| `timeout` | int (seconds) | `5` |

## Build-Time Assertions

`lib/agent-policy/assertions.nix` adds six entries to `config.assertions`. All checks run across every enabled provider. A failing assertion terminates `nix build` with the message shown.

| # | Condition | Error Message |
|---|---|---|
| 1 | `strategyLint.enabled → peerReviewProvider != null` | `strategyLint.enabled=true requires peerReviewProvider to be set` |
| 2 | `peerReviewProvider → provider exists in agentPolicy.providers` | `strategyLint.peerReviewProvider references a non-existent provider` |
| 3 | `phases.enforced → gatedTools != []` | `phases.enforced=true but gatedTools is empty` |
| 4 | `oracle.enabled → healthChecks != []` | `oracle.enabled=true but no healthChecks defined` |
| 5 | `async.enabled → backgroundTasks != []` | `async.enabled=true but no backgroundTasks defined` |
| 6 | `strategyLint.enabled → requiredSections != []` | `strategyLint.enabled=true but requiredSections is empty` |

## Mixins

Six mixin modules live in `lib/agent-policy/mixins/`. Each reads from `config.agentPolicy.providers` and writes to `config.agentPolicy._hooks.<mixin-name>`, the internal hook registry. The mixin is only active when the relevant option is enabled.

| Mixin | File | Trigger Option | Generated Hook Event | What It Produces |
|---|---|---|---|---|
| phase-gate | `phase-gate.nix` | `phases.enforced = true` | `PreToolUse` | Blocks `gatedTools` for L-complexity sessions without `.approved` marker |
| path-guard | `path-guard.nix` | provider `enable = true` | `PreToolUse` | Blocks Read/Write/Edit on patterns from `global.sensitivePatterns` |
| strategy-lint | `strategy-lint.nix` | `strategyLint.enabled = true` | `PreToolUse` | Validates strategy doc sections; gates on peer review file existence |
| reasoning-trace | `reasoning-trace.nix` | `reasoning.mode != "verbose"` | `PostToolUse` | Logs or filters tool output based on `silent` vs `log-only` mode |
| async-handshake | `async-handshake.nix` | `async.enabled = true` | `PostToolUse` | Captures Agent tool completion records; FIFO setup in activation |
| live-oracle | `live-oracle.nix` | `oracle.enabled = true` | `PostToolUse` | Runs health check commands after Write/Edit; reports failures |

## Hook Generation Flow

```mermaid
flowchart TD
    A["Provider module sets\nagentPolicy.providers.&lt;name&gt;\noptions"]

    B["Mixins evaluate options\nfor each enabled provider\nand write to\nagentPolicy._hooks.&lt;mixin&gt;.&lt;provider&gt;"]

    C["hook-adapters.nix\ngroupByProvider + groupByEvent\nconverts to provider-native format\nclaude: settings.json shape\ngemini: settings.json shape\ncodex: config.toml shape"]

    D["policy.nix assembler\nmaps each enabled provider\nthrough its format adapter\nproduces agentPolicy._assembledHooks"]

    E["Provider module reads\nagentPolicy._assembledHooks.&lt;name&gt;\ndeep-merges with base hooks\ngenerates final settings file"]

    F["sync-mutable-config.nix\nmkJsonSync / mkFileCopy\ninjects into mutable settings\nat home-manager activation"]

    G["Provider CLI\nreads settings file on startup\nhooks are live"]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
```

## Provider Implementations

### Claude (Orchestrator)

Full policy suite. Every mixin except async-handshake is active.

```nix
agentPolicy.providers.claude = {
  enable = true;
  reasoning.mode = "silent";
  reasoning.traceDir = "/tmp/agent-traces";
  oracle.enabled = true;
  oracle.healthChecks = [{
    command = "nix flake check --no-build 2>&1 | head -20";
    pattern = ".*\\.nix$";
    timeout = 60;
  }];
  oracle.streamAnalysis = true;
  phases.enforced = true;
  phases.stateDir = "/tmp/claude-complexity";
  phases.gatedTools = ["Write" "Edit" "NotebookEdit"];
  strategyLint.enabled = true;
  strategyLint.requiredSections = ["pre-mortem" "tradeoffs" "peer-review"];
  strategyLint.peerReviewProvider = "gemini";
  strategyLint.strategyPath = "/tmp/agent-strategy";
  hooks.format = "claude";
  hooks.outputPath = "~/.claude/settings.json";
  hooks.timeout = 5;
};
```

Active mixins: phase-gate, path-guard, strategy-lint, reasoning-trace, live-oracle.

Hook output format: `settings.json` with event keys mapping to arrays of `{ matcher, hooks: [{ type, command, timeout }] }` objects.

### Gemini (Researcher / Critic)

Async-capable configuration. Three background tasks, verbose reasoning.

```nix
agentPolicy.providers.gemini = {
  enable = true;
  reasoning.mode = "verbose";
  async.enabled = true;
  async.handshakeProtocol = "fifo";
  async.backgroundTasks = ["strategy-review" "blindspot-audit" "impact-analysis"];
  async.fifoDir = "/tmp/agent-handshake";
  hooks.format = "gemini";
  hooks.outputPath = "~/.gemini/settings.json";
  hooks.timeout = 5;
};
```

Active mixins: path-guard, async-handshake. (reasoning-trace is a no-op in verbose mode; phase-gate, strategy-lint, live-oracle are not enabled.)

### Codex (Logic Verifier)

Minimal configuration. Log-only reasoning, no other capabilities.

```nix
agentPolicy.providers.codex = {
  enable = true;
  reasoning.mode = "log-only";
  reasoning.traceDir = "/tmp/agent-traces";
  hooks.format = "codex";
  hooks.outputPath = "~/.codex/config.toml";
  hooks.timeout = 5;
};
```

Active mixins: path-guard, reasoning-trace.

Hook output format: `config.toml` with event keys mapping to arrays of `{ hooks: [{ type, command, timeout }] }` objects.

## Adding a New Provider

1. Create `modules/agents/<name>.nix`.
2. Set `agentPolicy.providers.<name> = { enable = true; hooks.format = "..."; ... }` with whatever capabilities the provider needs.
3. Ensure `policy.nix` is imported (it imports all mixins and the contract). This is typically handled by including the new module in `modules/agents/default.nix`.
4. If the provider uses a format not already in `hook-adapters.nix` (currently `claude`, `gemini`, `codex`), add a new format function to `hook-adapters.nix` that maps the internal `{ event, matcher, script }` structure to the provider's settings schema.
5. Run `nix build`. Assertions will catch any missing required options.

## Adding a New Mixin

1. Create `lib/agent-policy/mixins/<name>.nix`.
2. In the module body, read from `config.agentPolicy.providers` — filter to providers where the relevant option is enabled.
3. For each matching provider, generate a shell script using `pkgs.writeShellScript`.
4. Write hook entries to `config.agentPolicy._hooks.<name>` as an attrset of `{ event, matcher, script }` per provider name.
5. Add the new mixin to the imports list in `lib/agent-policy/policy.nix`. The hook will automatically appear in each matching provider's assembled settings after the next `just apply`.

## Adding a New Assertion

Add a new attrset to the `config.assertions` list in `lib/agent-policy/assertions.nix`:

```nix
{
  assertion = forAllEnabled (_: p:
    # your predicate — return true when the config is valid
    !p.someOption.enabled || p.someOption.requiredField != null);
  message = "[AgentPolicy] descriptive error message for the developer";
}
```

The `forAllEnabled` helper iterates over all providers where `enable = true` and short-circuits on the first violation. The message is printed by `nix build` when the assertion fails.

## Global Configuration

`agentPolicy.global` holds cross-cutting settings shared by all providers:

| Option | Default | Purpose |
|---|---|---|
| `stateRoot` | `"/tmp/agent-policy"` | Root directory for all phase state files |
| `sensitivePatterns` | `.env*`, `*.pem`, `*.key`, `secrets/*`, etc. | File patterns blocked by path-guard on all providers |
| `maxRetries` | `3` | Max consecutive failures before escalation-gate triggers |
