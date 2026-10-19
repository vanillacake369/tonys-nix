# AI Harness Verification Checklist

검증 기준: Phase 0~2 PRD FR-001~017. 2026-10-18 보완 구현 후 판정이다.
과거 결함은 [최초 감사](harness-verification-2026-10-18.md)에 보존하고,
현재 증거·잔여 작업은 [재검증 보고서](harness-reverification-2026-10-18.md)에 기록한다.
`satisfied`는 아래 명시한 범위에 한정하며 전체 운영 완료를 뜻하지 않는다.

## Sandbox

- [x] sandbox와 approval 필드를 분리한다.
- [x] cdx 기본값을 workspace-write/on-request로 변경한다.
- [x] Claude sandbox 활성화, unavailable 시 실패, unsandboxed 재시도 금지를 설정한다.
- [x] native conformance runner가 PASS/FAIL/UNAVAILABLE을 구분하고 미검증을 통과 처리하지 않는다.
- [x] Codex sandbox가 무해한 command에서도 exit 134로 중단되는 원인을 해결한다.
- [ ] 미설치 Claude/Gemini의 파일/네트워크 경계를 실제 검증한다.

판정: **partial**. Codex 0.162.1의 custom profile에 runtime 필수 read root인
`:minimal = read`를 생성한다. 격리 probe에서 reviewer `/usr/bin/true`는 exit 0,
workspace 밖 write는 exit 1, implementer workspace write는 exit 0이었다. Kiro native
agent validation도 통과했다. Claude/Gemini의 native 경계는 아직 통과 조건을 충족하지 못했다.

## Hooks

- [x] Claude 파일 path guard를 PreToolUse로 이동한다.
- [x] malformed JSON과 quoted sensitive path를 차단한다.
- [x] MCP PreToolUse adapter가 미지원 operation과 역할 누락을 차단한다.
- [x] PostToolUse는 결과 피드백으로 구분한다.
- [x] Claude SessionStart/Stop에 task baseline 및 completion adapter를 연결한다.
- [x] Codex/Gemini/Kiro에 lifecycle 및 retry adapter를 생성한다.
- [x] Kiro Stop의 exit-2 결과를 native block 응답으로 변환한다.
- [ ] 모든 code task 종료가 반드시 completion gate를 호출하는지 native runtime에서 검증한다.
- [ ] 모든 provider의 실행 전 경계와 hook 실패 처리를 실제 검증한다.

판정: **partial**. path regex는 보조 탐지이며 shell sandbox 대체물이 아니다.
모든 provider adapter에 lifecycle을 연결했고 static/build 검사는 통과했다. 실제 설치
runtime에서의 event schema와 차단 동작 검증은 Phase 0~2 잔여다.

## MCP

- [x] 실제 project policy schema와 role/skill gate를 일치시킨다.
- [x] reviewer/playwright 계약 충돌을 제거한다.
- [x] Claude Context7 읽기 method만 명시 역할/스킬로 허용한다.
- [x] 미지원 MCP는 생성 설정에서 제외하고 Kiro custom agent의 global MCP 상속을 끈다.
- [x] MCP 결과에 server/method/role/skill/risk/status/evidence JSONL을 기록한다.
- [x] timeout/ambiguous 결과를 `UNKNOWN`으로 보존한다.
- [x] decision ID, operation ID, request fingerprint가 없으면 MCP 호출을 차단한다.
- [ ] 실제 MCP method 호출과 decision evidence 연결을 native end-to-end 검증한다.

판정: **partial**. Context7는 기술 문서 조사 목적. Playwright, TickTick, Atlassian은
실행 adapter가 준비될 때까지 관리 설정에서 제공하지 않는다.
프로젝트/사용자가 별도로 추가한 서버를 관리 설정이 전부 통제한다고 주장하지 않는다.
Phase 0~2: 실제 경계 검증. Phase 5: 승인·멱등성·외부 조회 adapter.

## 작업지시서·Skill·Command

- [x] public command 4개, lifecycle skill 11개, VPP lineage 계약을 유지한다.
- [x] work command에 실제 검증 기록 및 completion gate 호출법을 연결한다.
- [x] Judge/Review는 권한 발급 주체가 아니다.

판정: **satisfied (정적 계약)**. provider 실사용 성공률은 별도 검증이다.

## Project-specific Harness

- [x] 프로젝트 docs/agent/ 정책과 글로벌 계약을 구분한다.
- [x] 계층 우선순위 100→40 및 명시된 deny/allow 충돌을 검증한다.
- [x] 기존 변경을 자동 commit/reset/stash하지 않는다.
- [ ] provider runtime이 project 설정의 모든 우회/완화를 차단하는지 검증한다.

판정: **partial**. 단순 JSON 충돌 검사만으로 OS/관리자 정책 강제성을 증명할 수 없다.
Phase 0~2 잔여: 실제 병합 결과와 managed policy 검증.

## Completion and Retry

- [x] 실제 검증 명령의 output/exit code/duration/commit을 recorder가 기록한다.
- [x] 실패·dirty snapshot·검증 중 변경이 있으면 DONE을 만들지 않는다.
- [x] completion에서 HEAD와 실행 commit을 대조한다.
- [x] root commit과 Git worktree를 지원한다.
- [x] test 파일 변경은 보수적으로 independent review 대기 상태로 차단한다.
- [x] design 완료는 코드 commit 대신 존재하는 artifact를 검증한다.
- [x] 공유 retry-budget의 BLOCKED 유지와 동시 접근 lock을 검증한다.
- [x] task baseline은 repository 단위로 보존하며 새 session ID로 초기화하지 않는다.
- [x] 모든 provider의 retry hook을 동일한 task/root-cause state에 연결한다.
- [x] provider failure event도 retry budget에 기록하고 BLOCKED task identity를 Stop으로 교체하지 않는다.
- [x] 외부 private receipt로 test-change 독립 리뷰를 commit/diff에 결속한다.
- [x] mandatory 작업은 repository 외부의 범위 제한 approval receipt 없이는 실행 계획을 차단한다.
- [x] approval/review receipt를 public-key fingerprint 및 RSA-SHA256 서명으로 검증한다.
- [x] 실행 runner가 agent 환경변수를 제거하고 OS 계정의 고정 public-key 경로만 사용한다.
- [ ] 운영 public key를 고정 trust path에 사용자 승인으로 provision한다.
- [ ] task 종료와 completion gate의 필수 연결을 검증한다.

판정: **partial**. standalone recorder/gates 및 review/approval handoff 회귀는 통과한다.
key 미설정·서명 누락·본문 변경은 fail-closed한다. 실행 runner는 agent가 전달한 key
환경변수를 제거하고 OS 계정의 고정 trust path만 사용한다. 현재는 운영 공개키가
provision되지 않아 위험 실행이 의도대로 차단된다.

## Provider Instruction SSoT

- [x] tonys-agent-harness/nix/agents/AGENTS.md를 공통 source로 유지한다.
- [x] Claude CLAUDE.md에 @AGENTS.md import를 export한다.
- [x] Gemini AGENTS context와 context.fileName을 설정한다.
- [x] provider source/import 정적 gate를 검증한다.
- [x] Kiro 2.31.1에서 reviewer config를 native validate하고 write tool 부재를 확인한다.
- [ ] Codex/Claude/Gemini의 실제 instruction loading과 reviewer 쓰기 거부를 검증한다.

판정: **partial**. Claude 2.1.300은 transient Nix 실행에서 config parse/doctor만
통과했고 credential이 필요한 instruction 실행은 검증하지 못했다. Gemini CLI 0.47.0은
upstream package가 대체 CLI로 전환 중임을 경고했다. Codex 0.162.1과 Kiro 2.31.1도
버전 확인만으로 instruction loading 전체를 통과 처리하지 않는다.

## Reviewer, Memory, External Operations

- [x] reviewer read-only 계약을 유지하며 Kiro MCP 상속을 차단한다.
- [x] memory . / .. namespace 및 내부 symlink 경로를 차단한다.
- [x] decoded daily 40줄/durable 120줄 제한을 write와 promote에 적용한다.
- [x] 새 기억은 unverified로 기록하고 secret-like key/value를 거부한다.
- [x] 외부 registry 동시 접근 및 다른 ID로 동일 요청 재예약을 차단한다.
- [x] UNKNOWN 동일 operation 재예약 거부를 유지한다.
- [x] memory entry별 동시 쓰기 lock과 일반 email/식별번호 반례를 차단한다.
- [x] 프로젝트별 `docs/agent/memory-policy.json` 추가 PII 패턴을 적용한다.
- [ ] secret/개인정보 분류의 완전성과 경로 교체 TOCTOU를 검증한다.
- [ ] reviewer native 권한과 외부 provider 실제 조회를 검증한다.
- [ ] memory 자동 요약·충돌·만료를 구현한다.

판정: **partial**. 파일 기반 핵심 반례는 수정. 자동 memory는 Phase 4,
실제 외부 조회는 Phase 5. 문자열 탐지로 모든 비밀정보/PII를 보장하지 않는다.

## Phase exit rule

Phase 0~2 전체 완료는 **보류**한다. 최소 정책 입력 누락, 원 감사 9개 반례,
추가 HUMAN_APPROVAL flag 우회는 차단했고 PRD ID/state 상호 대조도 구현했다.
서명 검증, runner key pinning, Codex sandbox exit 134 수정은 구현했다. 운영 공개키
provisioning은 사용자 승인 전까지 fail-closed 상태다. 그 외 필수 범위는 미설치 Claude/Gemini를 포함한 native
sandbox/hook/instruction/reviewer 부정 시험이다.
환경상 실행할 수 없는 검증을 스키마나 Nix build 통과만으로 완료 처리하지 않는다.
