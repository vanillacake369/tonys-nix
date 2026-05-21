# Gemini CLI Integration

Gemini CLI fills the researcher and critic role in the multi-provider setup. It operates in verbose reasoning mode, making its full thought process visible, and is the only provider configured to run tasks asynchronously via named FIFO pipes.

## Role

When Claude reaches the `STRATEGY` phase of its state machine, it dispatches one or more tasks to Gemini before presenting the strategy to the user. Gemini's job is to surface blind spots, enumerate risks, and challenge design assumptions — the same role a peer reviewer plays in a code review.

The three named tasks Gemini handles are:

| Task | Trigger | Output |
|---|---|---|
| `strategy-review` | Claude has a draft strategy document | Section-by-section critique written to `/tmp/agent-handshake/gemini/results/` |
| `blindspot-audit` | New feature design | List of edge cases and unconsidered failure modes |
| `impact-analysis` | Refactoring or system change | Downstream dependency analysis |

## Configuration

`modules/agents/gemini.nix` is the entry point. It:

1. Reads MCP server definitions from `config.programs.mcp.servers` (set in `mcp.nix`).
2. Passes them through `lib/mcp-adapters.nix` using the `gemini` adapter, which keeps only `command` and `args`.
3. Reads policy-generated hooks from `config.agentPolicy._assembledHooks.gemini`.
4. Merges base hooks with policy hooks per event name.
5. Generates a JSON settings file and syncs it to `~/.gemini/settings.json` via `mkJsonSync`.

The `programs.gemini-cli` home-manager module handles binary installation. The shared `dotfiles/shared/AGENTS.md` is injected as the `GEMINI` context file, giving Gemini the same behavioral instructions as the other providers.

### Generated settings.json structure

```json
{
  "mcpServers": {
    "context7": { "command": "npx", "args": ["-y", "@upstash/context7-mcp@latest"] },
    "playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] }
  },
  "hooks": {
    "AfterAgent": [
      { "hooks": [{ "type": "command", "command": "~/.claude/hooks/agent-notify.sh gemini", "timeout": 5 }] }
    ]
  }
}
```

Policy-generated hooks (from `async-handshake`, `path-guard`, `reasoning-trace` mixins) are appended to the relevant event arrays.

## Async FIFO Handshake

The async-handshake mixin (`lib/agent-policy/mixins/async-handshake.nix`) creates the infrastructure when Gemini's contract is evaluated:

**At `nix build` / `just apply` time:**

A home-manager activation script runs `async-setup-gemini.sh`, which creates:
```
/tmp/agent-handshake/gemini/
├── strategy-review.fifo
├── blindspot-audit.fifo
├── impact-analysis.fifo
└── results/
```

**At runtime:**

The `PostToolUse` hook (`async-handshake-gemini.sh`) fires when the `Agent` tool completes. It writes a completion record to `results/<session-id>-<timestamp>.json` containing session ID, completion time, and output length. Claude reads from this directory to confirm task completion.

The handshake uses files rather than blocking pipe reads to avoid deadlocks when the orchestrator and background agent share the same terminal session.

## Policy Profile

Gemini's contract implementation in `modules/agents/gemini.nix` activates the following capabilities:

| Capability | Setting | Effect |
|---|---|---|
| Reasoning | `mode = "verbose"` | Full reasoning chain visible in terminal; appropriate for research where the analysis is the value |
| Async | `async.enabled = true` | FIFO pipes created at activation; PostToolUse hook captures completion records |
| Async tasks | `backgroundTasks = ["strategy-review" "blindspot-audit" "impact-analysis"]` | One named pipe created per task |
| Handshake | `handshakeProtocol = "fifo"` | Uses named pipes in `/tmp/agent-handshake/gemini/` |
| Path guard | via `global.sensitivePatterns` | Sensitive file blocking inherited from the shared contract |
| Reasoning trace | `mode = "verbose"` | No trace file written (verbose mode is a pass-through) |

## Integration with Claude

Claude references Gemini as `strategyLint.peerReviewProvider = "gemini"` in its own contract. The strategy-lint mixin uses this reference to:

1. Check for the existence of `/tmp/agent-strategy/<session-id>-review.md` before allowing Write/Edit operations.
2. Block execution if the review file is missing and prompt the user to run the Gemini peer review first.

This creates a hard dependency: Claude cannot proceed to the `EXECUTION` phase for L-complexity tasks until Gemini has written a review file.

## Hook Pipeline

### PostToolUse

| Matcher | Hook | Source | Purpose |
|---|---|---|---|
| `Agent` | `async-handshake-gemini.sh` | Policy: async-handshake mixin | Captures task completion records |
| all | `reasoning-trace-gemini.sh` | Policy: reasoning-trace mixin | No-op in verbose mode (pass-through) |
| `Write\|Edit\|Read` | `path-guard-gemini.sh` | Policy: path-guard mixin | Blocks sensitive file access |

### AfterAgent

| Hook | Purpose |
|---|---|
| `agent-notify.sh gemini` | macOS system notification on session end |
