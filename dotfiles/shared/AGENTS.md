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

**Delegation boundary (읽기 전용 원칙):**
- `researcher`, `cross-validator` → 정보 수집/분석만 수행 (파일 수정 금지)
- `implementer`, `tester`, `refactorer` → Claude Native 실행만 허용 (proxy 위임 금지)
- 외부 모델(Gemini/Codex)에게 "구현"을 맡기지 않음. 연구/검증 용도로만 사용.

**After receiving a delegation result:**
- Verify it against your own judgment — do not blindly trust
- Synthesize multiple opinions into a final recommendation
- If proxy is unreachable, fall back to local tools or skip delegation

**Reverse-traverse escalation:**
- 하위 에이전트가 판단이 필요한 상황을 만나면 상위(orchestrator/사용자)에게 질의
- 절대 하위에서 독단적으로 방향을 결정하지 않음
- 에스컬레이션 시 `[ESCALATION]` 형식 사용 (Retry-Backoff Protocol 참조)

## Retry-Backoff Escalation Protocol

서브에이전트가 task를 받아 구현할 때 적용하는 실패 처리 규칙:

### Backoff Strategy

```
Attempt 1: 최초 접근법 시도
  → 실패 시 원인 분석 (로그, 에러 메시지, 타입 등)

Attempt 2: 다른 각도로 접근 (다른 API, 다른 알고리즘, 다른 구조)
  → 실패 시 두 접근의 실패 원인 비교 분석

Attempt 3 (최종): 최소 범위로 축소하여 핵심만 구현 시도
  → 실패 시 즉시 ESCALATION
```

### Escalation 조건 (즉시 상위로 보고)

- 3회 시도 후에도 해결 불가
- 요구사항이 모호하거나 상충
- 예상 범위를 초과하는 변경이 필요 (다른 모듈 수정 등)
- 2개 이상의 동등한 선택지가 있어 판단 불가
- 테스트 실패 원인이 설계 레벨일 때

### Escalation 보고 형식

```
[ESCALATION]
- Task: {할당받은 작업}
- Attempts: {시도한 접근법 요약}
- Failure reason: {각 시도의 실패 원인}
- Blocker: {핵심 차단 요인}
- Options: {A vs B — 판단 요청}
```

### 금지 사항

- 같은 접근을 반복하며 "다시 해보기" (brute force retry 금지)
- 실패를 숨기고 부분만 구현하여 "완료" 보고
- 에러를 무시하고 우회하는 hack 적용
- orchestrator 승인 없이 task 범위 확장

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
