# Claude Code Integration

Claude Code is the orchestrator in this multi-provider setup. It carries the most extensive policy configuration: phase enforcement, strategy linting, live verification, and path guarding. All other providers are invoked from Claude sessions.

## Configuration Files

Static assets are symlinked by `modules/agents/claude.nix` via `home.file`:

| Path | Source | Notes |
|---|---|---|
| `~/.claude/commands/` | `dotfiles/claude/commands/` | Slash command definitions |
| `~/.claude/agents/` | `dotfiles/claude/agents/` | Sub-agent definitions |
| `~/.claude/skills/` | `dotfiles/claude/skills/` | Skill definitions |
| `~/.claude/hooks/` | `dotfiles/claude/hooks/` | Hook shell scripts |
| `~/.claude/AGENTS.md` | `dotfiles/shared/AGENTS.md` | Shared agent instructions |

Dynamic settings are generated at `nix build` time and merged into mutable files at activation time:

| Target File | Content | Strategy |
|---|---|---|
| `~/.claude/settings.json` | Permissions, hooks (base + policy-generated) | `mkJsonSync` deep-merge |
| `~/.claude.json` | MCP server definitions | `mkJsonSync` deep-merge |

## Configuration Sync

`claude.nix` performs the following at activation:

1. Reads `dotfiles/claude/settings.json` as the base settings object.
2. Reads `config.agentPolicy._assembledHooks.claude` — the hooks assembled by the policy system at build time.
3. Deep-merges hook arrays per event name: base hooks come first, then policy-generated hooks.
4. Generates a Nix-store JSON file from the merged result.
5. The `syncClaudeSettings` activation script calls `mkJsonSync` to merge this file into `~/.claude/settings.json`, preserving any runtime keys Claude Code writes back (e.g., project data).

MCP servers follow the same pattern: `mcp-adapters.nix` produces the `claude` format (pass-through), which is merged into `~/.claude.json`.

## Hook Pipeline

All hooks read JSON from stdin, do their work, and exit with:
- `0` — allow the operation
- `1` — soft error (retry)
- `2` — block the operation

### UserPromptSubmit

| Hook | Purpose |
|---|---|
| `complexity-router.sh` | Injects S/M/L complexity classification prompt on the first turn of a session |

### PreToolUse

| Matcher | Hook | Source | Purpose |
|---|---|---|---|
| `Bash` | `cmd-guard.sh` | Manual | Blocks destructive shell patterns (rm -rf, git push --force to main) |
| `Bash` | `branch-guard.sh` | Manual | Prevents checkout/reset on protected branches |
| `Write\|Edit\|NotebookEdit` | `phase-gate-claude.sh` | Policy: phase-gate mixin | Blocks gated tools until L-complexity strategy is approved |
| `Write\|Edit\|NotebookEdit` | `strategy-lint-claude.sh` | Policy: strategy-lint mixin | Validates strategy document has required sections + peer review |
| `Write\|Edit\|Read` | `path-guard-claude.sh` | Policy: path-guard mixin | Contract-driven sensitive file blocking from `global.sensitivePatterns` |
| `Agent` | `cost-gate.sh` | Manual | Blocks sub-agent invocations above 80% context window |

### PostToolUse

| Matcher | Hook | Source | Purpose |
|---|---|---|---|
| `Bash` | `proxy-route.sh` | Manual | Logs tool call metadata to cli-proxy-api |
| `Bash` | `escalation-gate.sh` | Manual | Counts failures; auto-stashes at 3rd, sends human notification |
| `Bash` | `test-feedback.sh` | Manual | Parses test runner output, surfaces top error messages |
| `Write\|Edit` | `escalation-gate.sh` | Manual | Same failure tracking for file mutations |
| `Write\|Edit` | `auto-lint.sh` | Manual | Auto-formats files after writes |
| `Write\|Edit\|NotebookEdit` | `live-oracle-claude.sh` | Policy: live-oracle mixin | Runs `nix flake check --no-build` after every file mutation |
| all | `reasoning-trace-claude.sh` | Policy: reasoning-trace mixin | Strips chain-of-thought from output; logs to `/tmp/agent-traces/claude/` |

### Stop

| Hook | Purpose |
|---|---|
| `agent-notify.sh claude` | macOS system notification on session end |

## Slash Commands

Commands are Markdown files in `dotfiles/claude/commands/`. Claude Code reads them when the user types the corresponding `/` prefix.

| Command | File | Purpose |
|---|---|---|
| `/commit` | `commit.md` | SRP-based change separation and commit with conventional message format |
| `/create-pull-request` | `create-pull-request.md` | Analyze branch changes, generate PR title and description |
| `/scaffold` | `scaffold.md` | KISS skeleton code generation matching existing project patterns |
| `/code-enhance` | `code-enhance.md` | Quality, performance, and security analysis with actionable suggestions |
| `/debug-system` | `debug-system.md` | Systematic root cause analysis following a structured investigation flow |
| `/blog-korean` | `blog-korean.md` | 8-step Korean tech blog workflow from outline to final post |
| `/blog-refine` | `blog-refine.md` | Diagnose and improve existing blog posts for clarity and structure |
| `/test-doc-korean` | `test-doc-korean.md` | Korean test case documentation with scenario and expectation tables |
| `/reset-memory` | `reset-memory.md` | Clear conversation memory to start a fresh context |

## Sub-Agents

Seven specialized agents in `dotfiles/claude/agents/`. Each is a Markdown file defining the agent's role, tool permissions, and operating constraints. Claude Code spawns them using the `Agent` tool.

| Agent | File | Role | Key Tools |
|---|---|---|---|
| architect | `architect.md` | Technical planning and system design | Read, Write, Glob, Grep |
| implementer | `implementer.md` | Code implementation that matches existing patterns | Read, Write, Edit, Bash |
| tester | `tester.md` | Framework-adaptive test suite creation | Read, Write, Edit, Bash |
| reviewer | `reviewer.md` | Security, performance, and quality analysis | Read, Grep, Glob |
| refactorer | `refactorer.md` | Code optimization and dead-code removal | Read, Write, Edit, Bash |
| researcher | `researcher.md` | Gemini-powered research and web exploration | Bash, Read, WebFetch, WebSearch |
| cross-validator | `cross-validator.md` | Independent second opinion via GPT | Bash, Read, Grep, Glob |

## Skills

Three reusable skill definitions in `dotfiles/claude/skills/`. Skills are invoked automatically when the user's prompt matches a trigger phrase.

| Skill | Directory | Trigger Phrases | Purpose |
|---|---|---|---|
| architectural-planning | `skills/architectural-planning/` | plan, design, architecture, integrate | Feature design, migration planning, system integration |
| code-implementation | `skills/code-implementation/` | implement, write code, add feature, fix bug | Pattern-matching code changes that respect existing style |
| test-development | `skills/test-development/` | test, coverage, unit test, E2E | Framework-adaptive test suite generation |

## Policy Profile

Claude's contract implementation in `modules/agents/claude.nix` activates the following capabilities:

| Capability | Setting | Effect |
|---|---|---|
| Reasoning | `mode = "silent"` | Chain-of-thought logged to `/tmp/agent-traces/claude/`, not shown in conversation |
| Phase gate | `phases.enforced = true` | Write, Edit, NotebookEdit blocked until L-complexity strategy has `.approved` marker |
| Phase gate | `gatedTools = ["Write" "Edit" "NotebookEdit"]` | Exact tools that require approval |
| Strategy lint | `strategyLint.enabled = true` | Strategy document must contain `pre-mortem`, `tradeoffs`, `peer-review` sections |
| Strategy lint | `peerReviewProvider = "gemini"` | A Gemini review file must exist at `/tmp/agent-strategy/<session>-review.md` |
| Live oracle | `oracle.enabled = true` | `nix flake check --no-build` runs after every Write/Edit on `.nix` files |
| Live oracle | `streamAnalysis = true` | Failed checks are re-run with output captured for inline display |
| Path guard | via `global.sensitivePatterns` | `.env*`, `*.pem`, `*.key`, `credentials*`, `secrets/*`, `.ssh/*`, `.gnupg/*` are blocked on all providers |

## Modifying Claude Configuration

**Add or remove tool permissions**: edit `dotfiles/claude/settings.json` under the `permissions.allow` array, then run `just apply`.

**Add an MCP server**: edit `modules/agents/agents-mcp.nix` (single source of truth). The adapter automatically formats it for Claude, Gemini, and Codex. Run `just apply`.

**Add a hook**: for one-off hooks, add an entry directly to `dotfiles/claude/settings.json`. For policy-driven hooks that should apply across providers, create a `policy-<name>.nix` mixin module in `modules/agents/`. See [architecture/agent-policy-contract.md](../architecture/agent-policy-contract.md#adding-a-new-mixin).

**Add a slash command**: create a Markdown file in `dotfiles/claude/commands/`. The filename (without `.md`) becomes the command name.

**Add a sub-agent**: create a Markdown file in `dotfiles/claude/agents/`. Claude Code discovers it automatically.
