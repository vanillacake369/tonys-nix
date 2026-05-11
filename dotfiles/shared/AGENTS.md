# Agent Development Guide

A file for [guiding coding agents](https://agents.md/).

## Guardrails

- Do not install packages without checking build compatibility (babel/webpack/Node versions)
- Determine the package manager from lock files (yarn.lock/package-lock.json). Do not guess
- Do not duplicate reads of files that a subagent is already exploring
- Do not run snapshot test updates (-u) without first identifying the cause of changes
- Do not include more than 3 responsibilities in a single commit
- Do not write PR bodies in free-form format

## Orchestration

### Subagent Usage Criteria
- 3+ independent explorations -> parallel background agents
- 1-2 specific files -> direct read (faster than agents)
- Result feeds into next step -> foreground (must wait)
- Bulk file analysis (10+) -> delegate to subagent

### Deduplication
Once an agent is launched, do not read the same files from main. Wait for the agent result and use only that result.

### Multi-Provider Routing (Claude as orchestrator)

Claude Code is the orchestrator. All external provider calls go through cli-proxy-api (localhost:4001).

**Pattern B — Explicit delegation via proxy:**

| Condition | Provider | Command |
|-----------|----------|---------|
| Large context analysis (100K+ tokens, 10+ files) | Gemini | `curl -s $CLI_PROXY_URL/v1/chat/completions -d '{"model":"gemini","messages":[...]}'` |
| Sandboxed code execution / validation | Codex | `codex -q "..."` |
| Quick second opinion | Any | `curl -s $CLI_PROXY_URL/v1/chat/completions -d '{"messages":[...]}'` (proxy routes) |
| Everything else | Claude | direct or subagent |

**Pattern A — Automatic hook logging:**
PostToolUse hook automatically logs Bash calls to the proxy for cost tracking. No action needed.

Rules:
- Default is always Claude (direct or subagent). Only delegate when the advantage is clear
- Capture the other provider's stdout and use the result — do not blindly trust
- Never delegate security-sensitive operations (credentials, destructive git) to external providers
- When delegating, pass only the minimum required context
- If proxy is down ($CLI_PROXY_URL unreachable), fall back to direct CLI calls (codex/gemini)

## Commit Convention

```
type(scope): description

Optional body explaining why.
```
Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## PR Body Structure

```
## Overview
## Changes
## Tests
## Discussion
  ### Issue : ~~~
  ### Alternatives (table)
  > Reviewer requests
```
