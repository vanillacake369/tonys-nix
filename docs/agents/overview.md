# Multi-Provider Agent Orchestration

This repository coordinates three AI providers under a unified policy contract. Claude Code acts as the primary orchestrator, Gemini CLI handles research and critique, and Codex provides logic verification. A local proxy (cli-proxy-api) unifies authentication and cost logging across all three.

## Architecture

```mermaid
graph TD
    User([Developer])

    subgraph Providers
        Claude["Claude Code\n(Orchestrator)\nsilent reasoning\nphase-gate + strategy-lint\nlive oracle"]
        Gemini["Gemini CLI\n(Researcher / Critic)\nverbose reasoning\nasync FIFO handshake"]
        Codex["Codex\n(Logic Verifier)\nlog-only reasoning\nverification traces"]
    end

    subgraph Infrastructure
        Proxy["cli-proxy-api\nlocalhost:4001\nauth + cost logging\nround-robin routing"]
        MCP["MCP Servers\ncontext7\nplaywright"]
    end

    subgraph NixBuildTime["Nix Build Time"]
        Contract["lib/agent-policy/contract.nix\nOption interface"]
        Mixins["lib/agent-policy/mixins/\n6 capability modules"]
        HookAdapters["lib/agent-policy/hook-adapters.nix\nFormat conversion"]
        MCPAdapters["lib/mcp-adapters.nix\nSSoT transformation"]
    end

    User --> Claude
    Claude -->|"strategy-review\nblindspot-audit\nimpact-analysis"| Gemini
    Claude -->|"algorithm verification"| Codex
    Claude --> Proxy
    Gemini --> Proxy
    Codex --> Proxy
    Proxy --> MCP

    Contract --> Mixins
    Mixins --> HookAdapters
    HookAdapters --> Claude
    HookAdapters --> Gemini
    HookAdapters --> Codex
    MCPAdapters --> Claude
    MCPAdapters --> Gemini
    MCPAdapters --> Codex
```

## MCP Server Single Source of Truth

MCP servers are declared once in `modules/agents/mcp.nix` and adapted to each provider's required format by `lib/mcp-adapters.nix`. No provider-specific MCP configuration is written by hand.

```
modules/agents/mcp.nix          (canonical server definitions)
        |
        v
lib/mcp-adapters.nix            (SSoT transformer)
        |
        +---> claude format     (passed through as-is → ~/.claude.json)
        +---> gemini format     (command + args only → ~/.gemini/settings.json)
        +---> codex format      (adds enabled flag, renames headers → ~/.codex/config.toml)
```

Current servers: `context7` and `playwright`.

## Configuration Sync

Each provider has a dedicated Nix module in `modules/agents/`. All modules follow the same pattern: generate a settings file at `nix build` time, then use an activation script to merge it into the live mutable config.

| Provider | Nix Module | Sync Strategy | Target File |
|---|---|---|---|
| Claude | `modules/agents/claude.nix` | `mkJsonSync` (deep-merge) | `~/.claude/settings.json`, `~/.claude.json` |
| Gemini | `modules/agents/gemini.nix` | `mkJsonSync` (deep-merge) | `~/.gemini/settings.json` |
| Codex | `modules/agents/codex.nix` | `mkFileCopy` (overwrite + backup) | `~/.codex/config.toml` |

`lib/sync-mutable-config.nix` provides both helpers. Deep-merge preserves runtime data (OAuth tokens, project history, usage stats) that the provider CLIs write back to their config files.

Static assets (commands, agents, skills, hooks) are managed separately as read-only symlinks via `home.file` in `claude.nix`.

## Agent Policy Contract

The policy contract system (`lib/agent-policy/`) encodes the behavioral rules from `CLAUDE.md` as Nix module options that are validated at build time. Each provider declares its capabilities against a shared interface; Nix assertions reject invalid combinations before any code is deployed.

Full documentation: [architecture/agent-policy-contract.md](../architecture/agent-policy-contract.md)

## Provider Comparison

| Provider | Role | Reasoning Mode | Async | Oracle | Phase Gate | Strategy Lint |
|---|---|---|---|---|---|---|
| Claude | Orchestrator | silent | — | `nix flake check` | L-complexity gate on Write/Edit | Gemini peer review required |
| Gemini | Researcher / Critic | verbose | FIFO (3 tasks) | — | — | — |
| Codex | Logic Verifier | log-only | — | — | — | — |

**Reasoning modes:**

- `silent` — chain-of-thought is written to `/tmp/agent-traces/` but not shown in conversation; only decisions and actions surface
- `verbose` — full reasoning is visible in the terminal; appropriate for research tasks where the thought process is the output
- `log-only` — tool output is appended to trace files at `/tmp/agent-traces/codex/`; nothing is shown in conversation

## Inter-Provider Communication

Providers do not call each other directly. Communication happens through three mechanisms:

**FIFO pipes (Gemini async tasks)**

When Claude needs a strategy review, it writes a task description to a named pipe in `/tmp/agent-handshake/gemini/`. Gemini reads from the pipe, runs the analysis, and writes results to `/tmp/agent-handshake/gemini/results/`. Claude polls for the result file. The three supported task names are `strategy-review`, `blindspot-audit`, and `impact-analysis`.

**Shared state files (phase coordination)**

Phase state is stored as flat files in `/tmp/agent-policy/phases/<provider>/<session-id>`. The phase-gate hook reads this file before allowing Write or Edit calls. An `.approved` suffix signals that the strategy has been reviewed.

**agent-notify.sh notifications**

Each provider fires `~/.claude/hooks/agent-notify.sh <provider>` on session end. On macOS this triggers a system notification. The script is also used for human escalation when the escalation-gate hook detects repeated failures.

## Module Structure

```
modules/agents/
├── default.nix          # imports all provider modules
├── mcp.nix              # MCP server SSoT (programs.mcp.servers)
├── claude.nix           # Claude: dotfiles + activation + policy contract
├── gemini.nix           # Gemini: settings + policy contract
├── codex.nix            # Codex: config.toml + policy contract
└── proxy.nix            # cli-proxy-api binary + launchd service (macOS)

lib/
├── mcp-adapters.nix     # SSoT: programs.mcp.servers → per-provider format
├── sync-mutable-config.nix  # mkJsonSync + mkFileCopy helpers
└── agent-policy/
    ├── contract.nix     # Option interface (6 option groups)
    ├── assertions.nix   # 6 build-time contract checks
    ├── hook-adapters.nix # Hook format conversion (claude/gemini/codex)
    ├── policy.nix       # IoC assembler + activation entry point
    └── mixins/          # 6 capability modules
```
