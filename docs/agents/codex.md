# Codex Integration

Codex is the logic verifier in the multi-provider setup. It operates independently from Claude's primary reasoning path, providing a second opinion on algorithm correctness and implementation logic. Its reasoning mode is `log-only`: all output goes to trace files rather than the terminal.

## Role

Claude invokes Codex when it needs to verify:

- Complex algorithmic logic before committing to an implementation
- Non-obvious data transformations where off-by-one errors or edge cases are likely
- Concurrency patterns or state machine logic
- Cryptographic or security-sensitive code paths

Because Codex uses a different underlying model than Claude, its agreement or disagreement carries genuine signal. Disagreement is a prompt to re-examine the approach rather than proceed.

## Configuration

`modules/agents/codex.nix` is the entry point. It:

1. Reads MCP server definitions from `config.programs.mcp.servers` (set in `mcp.nix`).
2. Passes them through `modules/agents/mcp-adapters.nix` using the `codex` adapter, which adds an `enabled` flag and renames `headers` to `http_headers`.
3. Reads policy-generated hooks from `config.agentPolicy._assembledHooks.codex`.
4. Merges base hooks with policy hooks per event name.
5. Reads role, skill, agent, and permission bindings from `modules/agents/codex-bindings.nix`.
6. Generates a TOML config file and syncs it to `~/.codex/config.toml` via `mkTomlSync`.

Unlike Claude and Gemini which use JSON deep-merge, Codex uses a TOML-aware sync: activation backs up the existing file, writes the generated TOML, and preserves Codex-owned runtime state under `hooks.state`, `projects`, and `tui`. Nix remains the source of truth for hooks, MCP servers, agents, and permission bindings.

The `programs.codex` home-manager module handles binary installation. `dotfiles/shared/AGENTS.md` is injected as `custom-instructions`.

## Workflow Skills

`modules/agents/workflow-bindings.nix` promotes selected Claude slash commands
into Codex skills with the `workflow-*` prefix. The skill body keeps provenance
back to the original slash command and includes the full source prompt, while
the registry stores provider-neutral metadata such as recommended role,
argument hint, network/MCP needs, and whether the workflow mutates files.

Examples:

| Claude command | Codex skill | Typical Codex request |
|---|---|---|
| `/commit` | `workflow-commit` | `Use workflow-commit for the current diff` |
| `/create-pull-request` | `workflow-create-pull-request` | `Use workflow-create-pull-request and prepare the PR body` |
| `/debug-system` | `workflow-debug-system` | `Use workflow-debug-system for this failing test output` |
| `/code-enhance` | `workflow-code-enhance` | `Use workflow-code-enhance on modules/agents` |

The Codex skill treats any `$ARGUMENTS` placeholder in the source command as
the current user request and explicit context. Claude-only syntax is retained
as provenance, not as a requirement to use Claude-specific tools.

### Generated config.toml structure

```toml
[hooks]
[hooks.Stop]
[[hooks.Stop.hooks]]
type = "command"
command = "~/.claude/hooks/agent-notify.sh codex"
timeout = 5

[mcp_servers]
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp@latest"]
enabled = true

[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]
enabled = true
```

Policy-generated hooks from active mixins are appended to their respective event arrays.

## Policy Profile

Codex's contract implementation in `modules/agents/codex.nix` is minimal by design:

| Capability | Setting | Effect |
|---|---|---|
| Reasoning | `mode = "log-only"` | All tool output appended to `/tmp/agent-traces/codex/<session-id>.log` with timestamps; nothing displayed in the terminal |
| Trace directory | `traceDir = "/tmp/agent-traces"` | Session-specific log files accumulate here; useful for post-session analysis |
| Path guard | via `global.sensitivePatterns` | Sensitive file blocking inherited from the shared contract |
| Async | disabled | Codex operates synchronously; Claude waits for the response |
| Oracle | disabled | No health checks configured |
| Phase gate | disabled | No phase enforcement |
| Strategy lint | disabled | No strategy document requirements |

The minimal surface area is intentional. Codex is a targeted verification tool, not an orchestrator. Adding phase enforcement or async handshake would increase coordination overhead without benefit.

## Reasoning Traces

When `mode = "log-only"`, the reasoning-trace mixin (`modules/agents/policy-reasoning-trace.nix`) generates a `PostToolUse` hook that:

1. Reads `tool_output` from the JSON stdin payload.
2. Creates `/tmp/agent-traces/codex/<session-id>.log` if it does not exist.
3. Appends an ISO 8601 timestamp header followed by the full output.

Traces persist across session restarts and can be inspected to understand Codex's verification reasoning after the fact.

## Hook Pipeline

### PostToolUse

| Matcher | Hook | Source | Purpose |
|---|---|---|---|
| all | `reasoning-trace-codex.sh` | Policy: reasoning-trace mixin | Writes tool output to trace log; suppresses terminal display |
| `Write\|Edit\|Read` | `path-guard-codex.sh` | Policy: path-guard mixin | Blocks sensitive file access |

### Stop

| Hook | Purpose |
|---|---|
| `agent-notify.sh codex` | macOS system notification on session end |
