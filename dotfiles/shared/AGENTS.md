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

### Multi-Provider Delegation (Claude as orchestrator)

Claude Code is the orchestrator. `Agent(general-purpose)` is **denied** — use the specialized agents below instead.

**Routing table:**

| Task | Agent | Why |
|------|-------|-----|
| Research, docs, large-context analysis | `researcher` | Routes to Gemini (1M context, fast) |
| Cross-validation, second opinion | `cross-validator` | Routes to GPT (independent perspective) |
| Quick code search (1-3 files) | `Explore` (builtin) | Fastest for targeted lookups |
| Architecture planning | `architect` / `Plan` (builtin) | Claude reasoning strength |
| Implementation | `implementer` | Claude code generation |
| Code review | `reviewer` | Claude quality analysis |
| Refactoring | `refactorer` | Claude pattern recognition |
| Testing | `tester` | Claude test design |
| Direct proxy call | `Bash(curl)` | When no agent fits |

**Auto-delegation rules (no user prompt needed):**

- Research / web knowledge / docs → `researcher`
- Cross-validation of security, architecture, destructive changes → `cross-validator`
- 3+ independent explorations → parallel background agents
- 5+ files to analyze → `researcher` (Gemini large context)

**When NOT to delegate:**

- Simple file reads, edits, git operations — just do it directly
- Security-sensitive operations (credentials, destructive git)
- Trivial questions where delegation overhead > benefit

**Direct proxy call (when no agent fits):**

```bash
curl -s http://127.0.0.1:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  --data @- <<EOJSON | jq -r '.choices[0].message.content'
{
  "model": "gemini-2.5-flash-lite",
  "messages": [{"role": "user", "content": "YOUR PROMPT HERE"}],
  "stream": false
}
EOJSON
```

**After receiving a delegation result:**
- Verify it against your own judgment — do not blindly trust
- Synthesize multiple opinions into a final recommendation
- If proxy is unreachable, fall back to local tools or skip delegation

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
