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

Claude Code is the orchestrator. Delegate to other providers via cli-proxy-api when it makes the task better — not just bigger.

**When to delegate (do this automatically, no user prompt needed):**

- Cross-validation: before finalizing security reviews, architecture decisions, or destructive changes, get a second opinion from a different model
- Large input: when the context you need to analyze exceeds what fits comfortably (5+ files, long logs, big diffs)
- Different strength: Gemini for breadth (large context, web knowledge), GPT for code generation, Claude for reasoning and judgment
- Parallel speedup: when 2+ independent analyses can run at the same time

**When NOT to delegate:**

- Simple file reads, edits, git operations — just do it
- Security-sensitive operations (credentials, destructive git, secrets)
- When the overhead of delegation exceeds the benefit (trivial questions)

**How to delegate:**

```bash
# Send to a specific model
curl -s http://127.0.0.1:4001/v1/chat/completions \
  -H "Content-Type: application/json" \
  --data @- <<EOJSON | jq -r '.choices[0].message.content'
{
  "model": "gemini-2.5-flash-lite",
  "messages": [{"role": "user", "content": "YOUR PROMPT HERE"}],
  "stream": false
}
EOJSON

# Available models: gemini-2.5-pro, gemini-2.5-flash-lite, gpt-5.4-mini, gpt-5.4
# Check all: curl -s http://127.0.0.1:4001/v1/models | jq '.data[].id'
```

**After receiving a delegation result:**
- Verify it against your own judgment — do not blindly trust
- Synthesize multiple opinions into a final recommendation
- If proxy is unreachable, fall back to direct CLI (codex/gemini) or skip delegation

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
