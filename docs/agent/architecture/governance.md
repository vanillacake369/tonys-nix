# Engineering Governance MVP

Phase 0~2는 에이전트 수를 늘리는 대신 정책과 증거를 결정적으로 검사한다. 프로젝트별 PRD·ADR·Traceability·Telemetry는 저장소 산하 `docs/agent/`를 canonical root로 사용한다.

## Configuration precedence

`global-policy > project-policy > agent-role-permissions > skill-workflow-registry > mcp-registry > runtime-sandbox-approval > verification-evidence-policy` 순서다. 하위 계층은 상위 계층의 보안 거부, 비밀정보 차단, 파괴적 작업 승인, read-only 권한을 완화할 수 없다. 계약은 `tonys-agent-harness/nix/agents/contract-governance.nix`에 있다.

권한의 단일 권위는 결정적 `Policy Engine`과 `Execution Gate`다. 비결정적 LLM Judge는 advisory 판단만 제공하고, Review Gate는 finding·권고만 제공한다. 둘 다 쓰기·배포·승인 권한을 발급하거나 정책을 완화할 수 없다.

## Provider instruction source

`tonys-agent-harness/nix/agents/AGENTS.md`가 provider-neutral instruction SSoT다. Claude, Codex, Gemini, Kiro의 차이는 각 adapter가 표현하며, provider gate가 소스 존재와 참조 경로를 검사한다. Provider 기능이 동일하다고 추정하지 않고 capability contract와 실제 설정을 기준으로 한다.

## Runtime enforcement

The surface naming contract is documented in
`docs/agent/architecture/naming.md`. Commands are explicit entrypoints; skills are
reusable capabilities. A `skl-*` name never grants authority by itself, and a
`cmd-*` name never bypasses policy. VPP-derived skills retain their source
lineage through the `skl-vpp-*-ljh` namespace.

- Research/Review는 read-only permission profile을 사용한다.
- Implementation은 승인된 workspace에만 write한다.
- Secret 경로는 permission profile에서 deny한다.
- Release, production, migration, destructive 작업은 Decision Router의 explicit approval 없이는 진행하지 않는다.
- Hook은 보조 신호이고, 권한·sandbox·approval 정책이 단독 enforcement 경계다.

## Evidence and retry

`evidence-gate.sh`는 DONE에 실제 명령, exit code, 시간, 변경 파일, diff, 요구사항 결과, commit, 미해결 오류가 기록됐는지 확인한다. 실행하지 않은 테스트나 숨긴 실패는 통과하지 않는다.

`execution-plan.sh`는 Decision Engine의 승인 요청과 실제 승인 상태를 분리한다. scope digest가 일치하는 명시적 승인이 없으면 Phase 3~5 실행 계획은 `BLOCKED`이며, Phase 5는 항상 승인을 요구한다.

`retry-budget.sh`는 lifecycle이 발급한 task ID별 상태를 파일에 누적하고 동일 작업의
실패 3회에서 `BLOCKED`로 전환한다. provider failure event도 실패로 기록한다. 완료된
task만 새 ID로 진행하며 BLOCKED identity는 명시적 human resolution 없이 교체하지 않는다.

## Git and external operations

`git-lifecycle-gate.sh`는 코드 작업의 완료 전에 clean tree, scope, commit, evidence를 확인한다. 설계/조사 작업은 별도 mode로 처리한다. 외부 변경은 `external-operation.sh`의 operation ID와 request fingerprint를 먼저 예약하고, timeout은 `UNKNOWN`으로 기록한 뒤 조회 결과를 확인한다.

## Memory

`memory-lifecycle.sh`는 project namespace 아래에 session, daily, durable memory를 저장한다. 민감정보 패턴은 거부하고, durable 승격과 stale 표시를 명시적 명령으로 수행한다. 자동 요약·삭제 최적화는 후속 Phase다.

## Project Bootstrap MVP

`project-bootstrap`은 repository archaeology 결과를 바탕으로 Project Profile, AGENTS 보완안, provider 설정 diff, Skill/MCP 추천, 검증 정책, 영향 분석을 제안한다. 기존 파일을 승인 없이 변경하지 않는다.

## Deferred work

대시보드·외부 telemetry DB·자동 threshold tuning·고급 memory consolidation·실제 배포와 운영 데이터 변경은 후속 작업이며, 현재는 local telemetry summary와 외부 작업 idempotency preflight까지만 실행한다.
# Runtime enforcement additions

The deterministic boundary is now composed of the following controls:

- `path-guard.sh` denies secret-like paths and dangerous shell forms before a
  provider tool call. Claude wires it to Bash and file tools; other providers
  receive the same executable through the shared runtime hook directory.
- `mcp-allowlist-gate.sh` requires an explicit server/role/skill tuple. The
  project policy permits documentation research through `context7` and browser
  verification through `playwright`; mutation-capable integrations remain
  outside the default allowlist.
- `completion-gate.sh` composes evidence validation and the Git lifecycle gate.
  Code work cannot become DONE with unrun checks, unresolved errors, an
  uncommitted tree, or an evidence/commit mismatch.
- Retry escalation is persistent and fail-closed. Three failures leave the
  task BLOCKED; no hook performs `stash`, `reset`, rollback, or counter reset.
- Memory writes enforce project namespaces and line limits of 40 for daily and
  120 for durable records. Secret-like content is rejected.

Sandbox and approval are separate: the sandbox limits reachable resources,
while approval decides whether a boundary-crossing action may proceed. The
project adapter declares `workspace-limited` plus `fail-closed`; LLM judges and
reviewers remain advisory and cannot grant authority.

Mandatory approval and independent test-review receipts are signed outside the
repository. The runtime receives only `AGENT_APPROVAL_PUBLIC_KEY`; the matching
private key MUST remain outside the agent sandbox. `receipt-signature-gate.sh`
canonicalizes the JSON body, checks the public-key fingerprint, and verifies an
RSA-SHA256 signature before any scope or expiry field is trusted. An absent key,
unsigned receipt, changed field, or invalid signature fails closed.
The execution runner removes an agent-provided key variable and pins
`~/.config/agents/trust/approval-public.pem` using the OS account database,
not `$HOME`. Direct key overrides are suitable for gate unit tests only.

MCP use is intentionally explicit: a workflow must identify its role, skill,
decision ID, operation ID, and request fingerprint,
pass the allowlist gate, and record the resulting evidence before external
state is changed. Provider settings may expose read-oriented servers, but
exposure alone is not authorization.
