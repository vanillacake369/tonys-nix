# Hook Pipeline Reference

## How Hooks Work

Claude Code (and compatible providers) execute hook scripts at specific lifecycle events. Each hook receives a JSON payload on `stdin` describing the event context. Scripts communicate intent through their exit code:

| Exit Code | Meaning |
|---|---|
| `0` | Allow — proceed normally |
| `1` | Retry — surface the hook's stdout to the model as feedback |
| `2` | Block — abort the tool call; show stdout as the reason |

Hooks read the event payload with a pattern like:

```bash
input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
tool_input=$(echo "$input" | jq -r '.tool_input // empty')
```

The exact JSON schema varies by event type. `PreToolUse` events include `tool_name` and `tool_input`. `PostToolUse` events include `tool_output`. `UserPromptSubmit` includes the raw `prompt`.

## Full Pipeline

| Event | Matcher | Hook Script | Purpose | Generated |
|---|---|---|---|---|
| `UserPromptSubmit` | *(all prompts)* | `complexity-router.sh` | Classify prompt as S/M/L and inject the complexity tier into the conversation context | No |
| `PreToolUse` | `Bash` | `cmd-guard.sh` | Block destructive shell commands (`rm -rf /`, `git push --force` to main, etc.) | No |
| `PreToolUse` | `Bash` | `branch-guard.sh` | Prevent commits and force-pushes to protected branches | No |
| `PreToolUse` | `Write`, `Edit`, `Read` | `path-guard.sh` | Block access to `.env`, `secrets/*`, private keys, and other sensitive paths | No |
| `PreToolUse` | `Write`, `Edit`, `Read` | `complexity-gate.sh` | Require an S/M/L classification before allowing file mutations | No |
| `PreToolUse` | `Write`, `Edit`, `Read` | `phase-gate-claude.sh` | Enforce the RESEARCH → STRATEGY → EXECUTION state machine; block writes until strategy is approved | Yes* |
| `PreToolUse` | `Write`, `Edit`, `Read` | `path-guard-claude.sh` | Provider-specific path guard generated from the policy contract | Yes* |
| `PreToolUse` | `Write`, `Edit`, `NotebookEdit` | `strategy-lint-claude.sh` | Validate that a strategy document containing required sections (`pre-mortem`, `tradeoffs`, `peer-review`) exists before allowing writes | Yes* |
| `PreToolUse` | `Agent` | `cost-gate.sh` | Block sub-agent spawning when context usage exceeds 80% | No |
| `PostToolUse` | `Bash` | `proxy-route.sh` | Log token costs via cli-proxy-api; route to the appropriate provider endpoint | No |
| `PostToolUse` | `Bash` | `escalation-gate.sh` | Track retry count; escalate to human after repeated failures | No |
| `PostToolUse` | `Bash` | `test-feedback.sh` | Parse test output and return structured feedback to the model on failure | No |
| `PostToolUse` | `Write`, `Edit` | `escalation-gate.sh` | Same escalation tracking applied to file write failures | No |
| `PostToolUse` | `Write`, `Edit` | `auto-lint.sh` | Run the appropriate linter (`alejandra`, `ruff`, `prettier`, etc.) and return lint output as feedback | No |
| `PostToolUse` | `Write`, `Edit`, `NotebookEdit` | `live-oracle-claude.sh` | Run health checks (e.g. `nix flake check`) after mutations and block progression if they fail | Yes* |
| `PostToolUse` | *(all tools)* | `reasoning-trace-claude.sh` | Capture reasoning traces to `/tmp/agent-traces` (silent mode for Claude) | Yes* |
| `Stop` | *(session end)* | `agent-notify.sh claude` | Send a macOS notification when the Claude session ends | No |

*Marked **Yes** in the Generated column means the script is produced by the Agent Policy Contract system at `nix build` time. These scripts are not hand-written; they are rendered from mixin templates in `lib/agent-policy/mixins/` and written to `~/.claude/settings.json` via `home.activation.syncClaudeSettings`.*

## Agent Policy Contract Hooks

The four generated hooks correspond to policy mixins:

| Hook | Mixin Source | Policy Option |
|---|---|---|
| `phase-gate-claude.sh` | `lib/agent-policy/mixins/phase-gate.nix` | `agentPolicy.providers.claude.phases.enforced` |
| `path-guard-claude.sh` | `lib/agent-policy/mixins/path-guard.nix` | *(always active when provider is enabled)* |
| `strategy-lint-claude.sh` | `lib/agent-policy/mixins/strategy-lint.nix` | `agentPolicy.providers.claude.strategyLint.enabled` |
| `live-oracle-claude.sh` | `lib/agent-policy/mixins/live-oracle.nix` | `agentPolicy.providers.claude.oracle.enabled` |
| `reasoning-trace-claude.sh` | `lib/agent-policy/mixins/reasoning-trace.nix` | `agentPolicy.providers.claude.reasoning.mode` |

Changing any of these options and running `just apply` regenerates the corresponding scripts. Violations of contract invariants (e.g. enabling `strategyLint` without setting `peerReviewProvider`) cause `nix build` to fail with an assertion error before any scripts are written.

## Hook Location

All hand-written hook scripts live in `dotfiles/claude/hooks/`. The generated hooks are assembled into `~/.claude/settings.json` under the `hooks` key during `home.activation`. The base `settings.json` in `dotfiles/claude/settings.json` defines the static hooks; policy hooks are deep-merged on top per event array.

## Statusline Hooks

Two additional scripts manage the Claude terminal status line and are not part of the event pipeline:

| Script | Purpose |
|---|---|
| `statusline.sh` | 2-line status bar showing phase, complexity, turn count, and context |
| `subagent-statusline.sh` | Per-row status for sub-agent panels |

These are sourced by the terminal environment rather than invoked as hook scripts.
