# AI Harness 검증 보고서 — 2026-10-18

## 결론

검증 작업은 수행했으나 **Phase 0~2 전체 충족 / 운영 하네스 완료 판정은 불가**하다.
기존 체크리스트의 `satisfied` 일부는 선언이나 단위 테스트만으로 판정되어 있었다.
이번 보고서의 재판정이 해당 실행 보장에 대한 이전 판정을 정정한다.
기존 테스트 통과는 아래 재현 결함을 반증하지 않는다.

기준: `engineering-workflow-phase-0-2.md` PRD FR-001~017,
동명 testing 문서, `ai-harness-checklist.md`, governance 및 engineering-system 설계.
대상 HEAD: `98f2cdd2a7168a94dd0aa1dcb5603cf1c582618c` + 기존 미커밋 작업 트리.
HEAD만 재현하면 이번 검사 대상과 다르다. 점검 당시 tracked diff는 95 files,
3950 insertions / 207 deletions였다. 이 변경 전체를 이번 감사가 만든 것은 아니다.

## 검증 방식과 범위

A2A의 조사 → 검증 → 리뷰 → handoff 절차를 적용했다. 저장소 쓰기는
보고서·재현 스크립트·체크리스트의 보고서 링크에 한정한다. 별도 에이전트의
독립 리뷰를 실행한 것은 아니며, 단일 에이전트의 코드 검토와 실행 검증이다.
사전 점검: 기존 변경 보존, 실 credential 접근 없음, 외부 mutation 없음.
재현 fixture는 임시 디렉터리에만 생성한다. 위험 명령 문자열은 guard 입력일 뿐
실행하지 않는다. 고장 수리는 이번 검증 요청의 산출물에 포함하지 않는다.

## 체크리스트 재판정

`satisfied`는 명시한 검사 범위에서만 사용한다. `partial`은 일부 구현과 증거가
있지만 필수 연결/실행 검증이 부족함을, `not-satisfied`는 명시적 반례가 있음을 뜻한다.

| 항목 | 재판정 | 실제 처리 / 근거 | 남은 작업 |
|---|---|---|---|
| Sandbox / Approval 분리 | partial | 정책 필드는 분리됨. `modules/shell/fish.hm.nix:30`의 cdx는 `danger-full-access -a never`. 현재 감사 세션도 filesystem unrestricted | Phase 0~2: 실행 진입점에 workspace 경계 적용 및 실제 차단 검증 |
| 적합한 Hook | not-satisfied | Claude Bash는 PreToolUse guard. Read/Write/Edit는 PostToolUse에 path guard 등록되어 실행 전 차단 불가. 잘못된 JSON과 quoted path 통과 | Phase 0~2: pre-execution 연결·입력 검증·sandbox 통합 |
| MCP 구성·권한·용도 | not-satisfied | context7 조사 / playwright 브라우저 검증 목적은 정의됨. 실제 project-policy를 gate에 넣으면 정상 연구도 차단. role/skill gate 호출 연결 미확인 | Phase 0~2: schema와 호출 경계 정합성. Phase 5: 외부 mutation adapter |
| 작업지시서·Skill·Command | satisfied (정적 계약) | 4 public command, lifecycle skill 및 VPP lineage 계약, guard 회귀 검사 통과 | 실제 provider discovery/실행 성공까지 보장하는 판정은 아님 |
| 프로젝트별 harness | partial | 계층·프로젝트 파일·bootstrap 안내 존재. configuration gate는 이름이 같은 deny/allow 충돌 검사 | Phase 0~2: runtime policy 병합과 adapter별 유효 설정 검증 |
| 증거 기반 완료 | not-satisfied | exit code 등의 형식 검사 존재. 실제 result 없는 합성 DONE 통과. 실패 테스트 삭제/비활성화와 baseline 비교 없음 | Phase 0~2: 실행 증거 생성·무결성·테스트 변경 리뷰·completion 호출 연결 |
| Retry 3회 제한 | not-satisfied | 세 번째 실패는 BLOCKED. 이후 success 기록만으로 DONE 전환 재현 | Phase 0~2: BLOCKED 유지 및 승인된 재개, 안정적인 task/root-cause 식별 |
| Git lifecycle | partial | dirty tree 차단 테스트 통과. evidence commit 존재 및 일부 scope 검사 | Phase 0~2: HEAD/검증 snapshot 연결, root commit/워크트리 지원, completion 통합 |
| Provider 지침 SSoT | partial | 4 adapter의 AGENTS source 참조 grep 통과. Claude는 `.claude/AGENTS.md`만 export, Gemini는 context source 설정 | Phase 0~2: 실제 native import·버전별 로딩 증거. grep은 이를 증명하지 않음 |
| Reviewer 격리 | partial | reviewer read-only 계약과 provider projection 있음 | Phase 0~2: provider별 실제 쓰기 거부 테스트; 현재 세션의 skill 역할만으로 격리 보장 불가 |
| Memory | not-satisfied | session/daily/durable, stale/delete 제공. decoded 41줄 daily 저장 및 `..` namespace 허용 재현 | Phase 0~2: 경로·내용 제한 및 promote 검증. Phase 4: 자동 요약·충돌·만료 |
| 외부 작업 멱등성 | partial | 동일 operation ID 재예약/UNKNOWN 재시도 차단 단위 테스트 통과 | Phase 0~2: 미지원 실행 경로 차단 보장. Phase 5: provider 조회·동시성·실행 adapter |
| Decision / Human Gate | not-satisfied | 명시된 위험 signal은 Judge보다 우선함. signal 누락은 low-risk Judge 입력에서 AUTO_EXECUTE | Phase 1~2: 정책 schema completeness 및 모든 실행 진입점의 fail-closed 검증 |
| PRD / Traceability | not-satisfied | 17개 row 형식 검사 통과. verified의 모든 참조가 존재하지 않아도 통과 | Phase 0: PRD ID/state 대조, 로컬 경로/증거 검증 |
| 최소 Telemetry | partial | 기존 필드/프롬프트 제외 테스트 통과 | Phase 2: 모든 중요한 판단의 기록 연결·저장 실패 동작 검증. Phase 4 고급 분석은 유보 |

## Hook inventory와 적합성

- UserPromptSubmit: complexity router. 안내 기능이며 exit 0 자체가 실행 승인 근거가 아니다.
- PreToolUse Bash: command/path/branch guard. 현재 path guard는 문자열 정규식이며
  shell 전체 의미나 sandbox를 대체하지 못한다.
- PreToolUse Agent: cost gate. 비용 확인을 보안 승인으로 간주할 수 없다.
- PostToolUse Bash: escalation/test-feedback 등. 사후 관측이며 이미 실행한 작업을 막지 못한다.
- PostToolUse Read/Write/Edit/NotebookEdit: path guard 포함. secret 사전 차단 목적에 부적합하다.
- Stop: notification만 연결. `completion-gate.sh`는 설치되지만 Stop 연결은 없다.
- shared execution-plan: JSON 계획 산출. 실제 OS 실행 wrapper라고 볼 근거가 없다.

적합한 hook의 조건은 목적에 맞는 시점, schema 오류 시 차단, 우회 불가능한 호출
경계, provider별 실패 처리 증거다. 모든 provider가 같은 hook 종류를 가질 필요는
없지만 동등한 경계가 검증되어야 한다.

## 재현된 실패와 실행 결과

재현: `python3 docs/agent/testing/harness-audit-2026-10-18.py`
결과: **exit 1, 12 checks / 3 passed / 9 failed**. 실패를 보존한 감사용 검사이며
일반 CI에 연결하지 않았다. 아래 시간은 개별 subprocess의 측정값이다.

| 검사 | 기대 | 실제 | 시간 |
|---|---|---|---|
| malformed hook JSON | exit 2 | exit 0 | 19ms |
| `cat ".env"` 문자열 guard | exit 2 | exit 0 (파일 읽기 실행 안 함) | 13ms |
| 실제 project-policy의 context7/researcher 허용 | exit 0 | exit 2 | 7ms |
| 실제 result 없는 DONE evidence | exit 2 | exit 0 | 10ms |
| 동일 task 1/2/3회 실패 | 0/0/2 | 0/0/2, 통과 | 12/12/11ms |
| BLOCKED 후 success 기록 | exit 2 | exit 0, DONE | 17ms |
| decoded daily 41줄 | exit 2 | exit 0 | 30ms |
| namespace `..` | exit 2 | exit 0 | 33ms |
| nonexistent verified references | exit 2 | exit 0 | 10ms |
| policy_signals 누락 | BLOCKED | exit 0, AUTO_EXECUTE | 27ms |

원인 위치:

1. `governance/path-guard.sh`: jq 실패 `|| true`, 정규식 따옴표 경계 누락.
2. `governance/mcp-allowlist-gate.sh`: `.servers`를 읽으나 project policy는
   `.mcp_allowlist.servers`. 추출 adapter와 실제 호출 연결이 필요하다.
3. `governance/evidence-gate.sh`: `commands[].result` 필수 조건 없음.
   non-DONE 입력은 성공 반환하므로 completion 호출자도 상태를 검증해야 한다.
4. `governance/retry-budget.sh`: success가 기존 BLOCKED보다 우선한다.
5. `governance/memory-lifecycle.sh`: JSON 직렬화의 개행을 세며, `.`/`..` 허용.
   promote에도 줄 제한이 없다. 새로운 기억은 모두 confirmed로 기록한다.
6. `orchestrator/traceability-gate.sh`: 필드 비어 있음만 검사하며 실제 경로/PRD를 읽지 않는다.
7. `orchestrator/decision.sh`: 누락 policy_signals를 `{}`, 누락 위험 flag를 false로 치환한다.

경로 접두사는 `tonys-agent-harness/nix/agents/`이다. 추가 정적 발견: git gate는 `.git` 디렉터리를
요구하여 linked worktree를 거부하며, root commit diff에 `--root`가 없다.
MCP project allowlist의 reviewer/playwright는 role contract의 reviewer MCP=[]와
충돌한다. browser 도구의 `mutation:false` 선언만으로 외부 변경을 방지할 수 없다.
외부 registry는 caller가 VERIFIED를 기록할 수 있고, provider 조회 증거를 검증하지 않는다.

## 기존 검증 결과와 한계

| 명령 | 결과 |
|---|---|
| `bats tests/hooks/governance.bats tests/hooks/orchestrator-router.bats` | exit 0, 42/42 |
| `just _test-guard` | exit 0, 108/108 |
| `just test-hooks` | exit 0, 151/151 |
| `just lint` | exit 0; deadnix/statix/alejandra 통과 |
| `git diff --check` | exit 0; tracked diff whitespace 검사 통과 |
| `bash tonys-agent-harness/nix/agents/orchestrator/traceability-gate.sh docs/agent/traceability/requirements.tsv` | exit 0, 17 requirements |
| `bash tonys-agent-harness/nix/agents/governance/provider-instructions-gate.sh .` | exit 0, source 참조 검사 |
| `bash tonys-agent-harness/nix/agents/governance/configuration-gate.sh docs/agent/project-policy.json` | exit 0, 계층/명시 충돌 검사 |

위 focused 42건은 전체 hook suite의 부분집합이며 별개 테스트 수로 합산하지 않는다.
Nix activation/build와 provider 실제 도구 실행·MCP 호출은 이번 감사에서 수행하지 않았다.
설치된 Codex CLI는 `0.158.0`; `codex --help`의 approval 선택지는 `on-request`,
`never`, sandbox 선택지는 `read-only`, `workspace-write`, `danger-full-access`였다.
따라서 `never` 자체를 sandbox라고 볼 수 없고, 이 버전에서 `untrusted`는 선택지에 없다.
[공식 security 문서](https://learn.chatgpt.com/docs/security)를 2026-10-18 확인했으나
구체 CLI flag 판정은 설치 버전 help에 근거한다. Claude/Gemini/Kiro의 설치 버전별
native 동작은 미검증이다.

## PRD별 coverage

- FR-001: 형식/상태 단위 검사 통과, 존재하지 않는 verified 참조 반례 → not-satisfied.
- FR-002: 기존 risk route 테스트 통과, 실제 실행 연결 미검증 → partial.
- FR-003~004: 명시된 mandatory signal 우선순위/승인 digest 테스트 통과,
  누락 policy 반례와 호출 경계 미검증 → not-satisfied.
- FR-005: 질문/조사 routing 테스트 통과, 이미 답한 질문 dedup 증거 부족 → partial.
- FR-006~007: 기본 decision/telemetry 출력 검사 통과, 모든 경로 기록은 미검증 → partial.
- FR-008: 계약 회귀 통과, 설치된 provider 실제 동작 미검증 → partial.
- FR-009: 위험 변경 PRD 존재 테스트 통과. 존재 자체가 해당 변경 요구사항 연결을 보장하지 않음 → partial.
- FR-010~012: 정적 naming/lineage 계약 검사 범위 satisfied; provider 실행 사용성은 미검증.
- FR-013: 체크리스트는 존재하며 이번 보고서로 실제 충족 여부 정정.
- FR-014~015: pre-execution/MCP 경계 결함 → not-satisfied.
- FR-016: source 공유는 확인, native loading 미검증 → partial.
- FR-017: namespace/줄 제한 반례 → not-satisfied.

## 우선순위와 다음 착수 조건

1. P0 / Phase 0~2: 실행 sandbox, pre-tool gate, policy 누락 차단, MCP 호출 경계를
   먼저 연결한다. 연결이 없는 경로는 실행 불가여야 한다. 실제 provider 부정 테스트 필요.
2. P0 / Phase 0~2: completion 증거 생성과 commit snapshot 연결, 실패 테스트 삭제
   탐지, BLOCKED retry 유지. 위 감사 반례를 정식 회귀 테스트로 옮긴 뒤 수정한다.
3. P1 / Phase 0~2: memory namespace/decoded limits/promote, PRD/state/artifact 대조,
   provider instruction loading과 reviewer 실제 쓰기 차단을 검증한다.
4. Phase 3~5: 위 필수 항목 통과 후 별도 범위로 진행. 자동 memory, 외부 상태 조회,
   dashboard/ROI는 유보하되 미지원 외부 실행 차단은 현재 단계의 의무다.

## Git 및 완료 상태

보고서 작성 완료는 code task DONE 또는 Phase 완료가 아니다. 저장소는 기존
미커밋 변경이 많으며 commit/PR/배포하지 않았다. 이번 수정은 이 보고서,
감사 재현 스크립트, 원 체크리스트의 정정 안내뿐이다. `.github/workflows/ci.yml`
변경 없음. 미해결 결함은 위 표에 보존했다.
