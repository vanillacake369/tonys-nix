# Harness 보완 구현 및 재검증 — 2026-10-18

## 결과

최초 감사의 9개 재현 실패를 수정했다. 동일 감사는 **12/12 통과**한다.
추가 회귀 suite는 lifecycle·approval·review·MCP·memory 검사를 포함해 23건으로 확장했다. 최종
전체 `just test`는 **exit 0**, hooks **174/174**,
guard **108/108**, provider 설정 동기화 및 Home Manager activation 산출물 build가 통과했다.
이는 실제 사용자 환경 activation/배포 또는 전체 Phase 0~2 완료를 뜻하지 않는다.
**구현 상태: partial — 아래 runtime 필수 연결이 남아 있다.**

검증 기준은 기존 Phase 0~2 PRD와 [현재 체크리스트](ai-harness-checklist.md)다.
[작업 목록](../testing/harness-remediation.md),
[최초 감사](harness-verification-2026-10-18.md)를 함께 보존한다.
이번 작업은 기존 dirty worktree를 바탕으로 한 single-writer 구현과 직접 검증이다.
독립된 다른 모델/에이전트의 리뷰를 수행했다고 주장하지 않는다.

## 변경 및 근거

| 작업 | 구현 | 재검증 |
|---|---|---|
| Hook fail-closed | malformed payload 차단, quoted sensitive path 탐지, Claude 파일 guard PreToolUse 이동 | 원 감사 및 hook placement 검사 통과 |
| Sandbox 기본값 | cdx workspace-write/on-request, Claude sandbox enabled/failIfUnavailable/unsandboxed fallback 금지 | Nix build/정적 확인. 설치 runtime 미검증 |
| Decision | 6개 위험 boolean 필수화; 정책 누락을 false로 추론하지 않음 | 기존 routing 회귀 및 누락 정책 반례 통과 |
| 실행 계획 | HUMAN_APPROVAL action은 boolean flag를 제거해도 실행 불가 | 추가 부정 테스트 통과 |
| MCP | project schema 정합, reviewer/playwright 충돌 제거, Claude Context7 method/role/skill gate | 허용 연구 경로·역할 누락·외부 mutation 차단 통과 |
| 미지원 MCP | 관리 export에서 제외, Kiro custom agent global MCP 상속 해제, JSON sync의 stale MCP 병합 방지 | guard 및 설정 sync build 통과 |
| Evidence | 실제 command/결과/exit/duration/commit recorder 추가; 결과 없는 evidence 거부 | 실제 exit 7 보존 및 clean root commit 완료 검사 통과 |
| Git completion | HEAD/실행 commit/clean tree 대조, root commit 및 linked worktree 형식 지원 | dirty snapshot 거부 및 root commit 성공 검사 통과. linked worktree 실험은 미수행 |
| Test 변경 | recorder가 변경 test 파일을 보수적으로 review 대기로 차단 | 코드 검토. 모든 파일명/언어를 탐지한다는 보장은 없음 |
| Task lifecycle | Claude SessionStart/Stop 연결, repo 단위 baseline 보존, 변경 code scope/evidence 필수 | baseline 누락 거부, 새 session ID로 재시작해도 code 변경 차단, 문서 작업 허용 테스트 통과 |
| Design completion | artifact 존재와 unresolved error 확인; 코드 commit 불필요 | 별도 design fixture 통과 |
| Retry | 기존 BLOCKED를 success로 해제하지 않음, 파일 lock 추가 | 3회 실패/이후 success/lock 테스트 통과 |
| Memory | namespace . / .. 및 내부 symlink 거부, decoded 줄 제한, promote 검사, 새 사실 unverified | 40줄 허용/41줄 거부/121줄 durable 승격 거부/경로 탈출 차단 통과 |
| Traceability | verified artifact가 실제 파일인지 확인, schema 통과 메시지와 최종 통과 분리 | nonexistent artifact 거부, 17개 실제 row 형식 검사 통과 |
| SSoT export | Claude @AGENTS.md import, Gemini AGENTS context/fileName | static reference gate 통과; CLI 실제 로딩 미검증 |
| 외부 operation | registry lock 및 다른 ID로 같은 provider/target/fingerprint 재예약 차단 | UNKNOWN 재예약 및 ID 변경 우회 테스트 통과 |
| Approval boundary | mandatory 실행은 repository 외부 private receipt의 digest/action/environment/expiry를 검증 | inline 승인 거부 및 scoped receipt 승인 테스트 통과 |
| Test review | `REVIEW_REQUIRED` evidence를 외부 독립-review receipt의 commit/test digest에 결속 | receipt mismatch 거부 및 정상 해제 테스트 통과 |
| Provider lifecycle/retry | Codex/Gemini/Kiro start/stop 및 공통 retry adapter 생성 | 정적 계약, Nix build, task identity 회귀 통과; native 실행 미검증 |
| MCP outcome audit | post-hook이 최소 JSONL evidence를 기록하고 timeout을 UNKNOWN으로 보존 | timeout fixture 통과 |
| PRD/TSV | PRD heading ID/status와 traceability row를 상호 대조 | 현재 17개 requirement 대조 통과 |
| Memory concurrency/PII | entry lock과 일반 email/식별번호 거부 추가 | lock contention/email fixture 통과 |

## TDD 및 회귀 증거

1. 구현 전 원 감사 실행: exit 1, 12 checks / 3 passed / 9 failed.
2. 첫 보완 후 macOS `/var` alias를 namespace symlink로 오인하여 memory 회귀 2건 실패.
   검사 경계를 configured memory root 내부로 바로잡았다. 실패 assertion은 삭제하지 않았다.
3. 추가 suite 최초 실행: 8건 중 HUMAN_APPROVAL flag 우회, 미구현 recorder 2건 실패.
   구현 후 통과했으며 추가 integration 검사를 더해 12건으로 확장했다.
4. 첫 full `just test`: hook 159건 통과 후 Kiro context7 자동 노출을 기대하던 Nix
   fixture에서 실패. 미지원 MCP 차단 정책에 따라 fixture를 empty registry assertion으로
   변경했다. 사용자 custom seed 보존 검사는 유지했다.
5. 최종 `time just test`: exit 0, **163/163 hooks**, Nix 검사 전부 통과.
   **1:02.38 total**, 22.74s user / 10.75s system.
6. 마지막 memory key 검사·test filename 탐지 보완은 focused
   `bats tests/hooks/harness-remediation.bats tests/hooks/governance.bats` **31/31**, exit 0으로 재검증했다.
7. `just _test-guard`: exit 0, **108/108**.
8. `just lint`: exit 0, deadnix/statix/alejandra 모두 통과.
9. `git diff --check`, 설정 JSON 파싱, provider instruction gate,
   configuration gate, actual traceability gate: 모두 exit 0.
10. Task lifecycle 최초 2개 테스트 실패를 확인한 뒤 adapter를 구현했다.
    repository baseline은 metadata를 사용하여 secret 파일 내용을 읽지 않는다.
    timestamp 복원/동일 사용자 state 위조 방지는 OS runtime 경계의 책임이다.
11. Lifecycle까지 포함한 최종 `time just test`: **exit 0, 165/165 hooks**,
    설정 sync 2개, guard 108/108, Home Manager activation 산출물 build 모두 통과.
    **1:08.04 total**, 22.56s user / 11.06s system. 최종 focused suite 14/14,
    lint/guard, JSON 파싱 및 diff whitespace 검사를 다시 통과했다.
12. 두 번째 보완 wave의 6개 신규 시나리오는 구현 전 모두 실패했다. 첫 구현 후
    test-review completion은 recorder가 `REVIEW_REQUIRED`를 exit 0으로 반환해 실패했고,
    fail-closed exit 2로 수정했다. 새 script 실행 권한 누락도 회귀에서 발견해 수정했다.
13. 첫 full run은 hooks **174/174** 통과 후 Codex/Gemini provider timeout 단위 guard에서
    실패했다. 기존 provider 계약(초/밀리초)에 맞춰 수정한 뒤 guard **108/108** 및 최종
    `time just test` **exit 0, 174/174**, **1:15.01 total**로 통과했다.
14. Kiro Nix 파일을 repository formatter로 정리한 뒤 `just lint` exit 0 및 최종
    `time just test` **exit 0, 174/174, guard 108/108, 1:01.36 total**로 다시 통과했다.
15. 최종 보완 wave에서 receipt 서명/변조 검증, native conformance runner, MCP correlation,
    project PII policy를 추가했다. `just lint` exit 0, `time just test` **exit 0,
    175/175, guard 108/108, 1:12.10 total**로 통과했다.
16. 실행 runner의 key path를 OS account 기반 trust path로 고정한 뒤 최종 `just lint`
    **exit 0**, `time just test` **exit 0, 175/175, guard 108/108, 1:06.58 total**로
    다시 통과했다.

## 최종 native conformance 결과

2026-10-18 격리 실행 결과 전체 상태는 `INCOMPLETE`다.

| Provider | 결과 | 증거 |
|---|---|---|
| Codex 0.158.0 | FAIL | `codex sandbox`가 `/usr/bin/true`에서도 exit 134 |
| Kiro 2.31.1 | PASS | `agent validate --path` 통과, reviewer tools=`["read"]` |
| Claude | UNAVAILABLE | 실행 파일 미설치 |
| Gemini | UNAVAILABLE | 실행 파일 미설치 |

미설치 또는 crash를 Nix build/정적 설정 통과로 대체하지 않는다. Receipt 서명 검증은
본문 변조를 막고, 실행 runner는 agent의 key 환경변수를 제거한 뒤 OS 계정의 고정 trust
path만 사용한다. 공개키가 아직 provision되지 않았으므로 위험 실행은 fail-closed한다.

원 감사 12건은 추가 Bats suite에서도 실행한다. focused suite와 full suite는
중복이므로 합산하여 별개 검증 수로 보고하지 않는다. 테스트 fixture가 나타내는
증거와 실제 프로젝트 테스트 실행 결과를 구분한다.

## 영향이 있는 기본 동작 변경

- `cdx`는 다음 설정 적용 후 sandbox를 사용한다. 현재 이미 열린 세션은 변하지 않는다.
- 지원되지 않은 MCP를 자동 노출하지 않는다. Claude에서 허용되는 Context7 읽기 호출도
  `AGENT_ROLE=researcher|architect`, 해당 `AGENT_SKILL`, project policy가 필요하다.
  환경의 역할 선언만으로 외부 mutation 권한을 얻을 수 없다. 미지원 method는 거부한다.
- Codex/Gemini/Kiro 관리 MCP export는 비어 있다. Kiro 사용자 전역 MCP seed는 보존하되
  관리 custom agent에서는 `includeMcpJson=false`로 상속하지 않는다.
- 관리 JSON MCP sync는 기존 설정을 backup한 뒤 server registry를 교체하도록 변경했다.
  이번에는 실제 sync/activation을 사용자 홈에 실행하지 않았다. 적용 전 기존 custom
  MCP를 확인해야 하며, backup은 원 설정 복구에 사용할 수 있다.
- recorder의 출력 파일은 overwrite하지 않는다. 코드 DONE 검증은 clean snapshot을
  요구하므로 현재처럼 작업 트리에 변경이 남으면 BLOCKED evidence가 정상이다.
- 테스트 변경은 독립 리뷰 receipt가 commit 및 변경 test digest와 일치할 때만 해제된다.
  실패를 숨기기 위해 recorder JSON을 편집하거나 테스트를 지우면 안 된다.
- Claude lifecycle hook은 repo별 baseline을 외부 state directory에 유지한다.
  코드 변경 후 종료하려면 launch 환경의 `AGENT_COMPLETION_EVIDENCE`와
  `AGENT_TASK_SCOPE`가 실제 증거/scope 파일을 가리켜야 한다. 없으면 exit 2다.
  같은 repo의 새 세션은 기존 baseline을 재사용한다. 동시 세션은 파일 lock으로
  state 기록을 직렬화하되 전체 작업의 single-writer lease까지 구현한 것은 아니다.

## 이번 변경 파일

`tonys-agent-harness/nix/agents/governance/`:
`path-guard.sh`, `mcp-allowlist-gate.sh`, `mcp-hook.sh`,
`evidence-gate.sh`, **`record-verification.py` (신규)**, `completion-gate.sh`,
**`task-lifecycle.py` (신규)**,
`git-lifecycle-gate.sh`, `retry-budget.sh`, `memory-lifecycle.sh`,
`configuration-gate.sh`, `provider-instructions-gate.sh`, `external-operation.sh`,
**`approval-gate.sh`**, **`test-review-gate.sh`**, **`retry-hook.sh`**,
**`pre-tool-gate.sh`**, **`kiro-stop.sh`**.

연결부:
`tonys-agent-harness/nix/agents/orchestrator/{decision,execution-plan,execution-authorize,traceability-gate}.sh`,
`tonys-agent-harness/nix/agents/runtime-{hooks,provider-settings,settings-sync}.nix`,
`tonys-agent-harness/nix/agents/providers/claude/{module.nix,settings.json}`,
`tonys-agent-harness/nix/agents/providers/gemini/module.nix`, `tonys-agent-harness/nix/agents/providers/kiro/render.nix`,
`modules/shell/fish.hm.nix`,
`tonys-agent-harness/nix/agents/workflows/commands/cmd-vpp-work-ljh.md`, `docs/agent/project-policy.json`.

검증/문서:
`tests/hooks/{governance,orchestrator-router,harness-remediation}.bats`,
`tests/guard/agents.test.nix`, `tests/agent-config.check.nix`,
`docs/agent/testing/harness-remediation.md`, checklist 및 이 보고서.

## 남은 필수 작업과 착수 조건

| 우선순위 / 소속 Phase | 남은 작업 | 완료 조건 |
|---|---|---|
| P0 / 0~2 | native runtime 검증 | Codex exit 134와 Kiro native config는 해결. Claude/Gemini lifecycle/sandbox/instruction 부정 시험 필요 |
| P0 / 0~2 | approval key provisioning | 사용자가 공개키를 고정 trust path에 provision한 뒤 실제 보안·운영 변경 승인/거부 시험 |
| P1 / 0~2 | native MCP 실행 검증 | correlation schema는 완료. 실제 허용 MCP 응답 및 timeout 후 provider 조회 전 재호출 금지를 end-to-end 검증 |
| P1 / 0~2 | memory TOCTOU·개인정보 정책 | lock 획득 후 경로 교체 공격과 프로젝트별 PII 분류 정책 테스트. 정규식으로 모든 개인정보를 보장하지 않음 |
| 이후 Phase 4/5 | memory 자동화, 외부 조회/실행 adapter, telemetry 분석 | 앞의 최소 경계 검증 후 별도 범위로 착수 |

Claude/Gemini 실행 파일은 현재 PATH에 상시 설치되어 있지 않다. transient Nix 실행에서
Claude **2.1.300** doctor와 Gemini CLI **0.47.0** version을 확인했지만 model/hook 실행은
검증하지 못했다. Codex **0.162.1**, Kiro **2.31.1**을 확인했다. Nix build 통과는
설치된 CLI의 실제 동작 증거가 아니다.
다음 가장 작은 작업은 설치 provider의 hook schema를 확인하여 공통 lifecycle의
나머지 adapter를 연결하고 임시 프로젝트에서 code/design 종료를 검증하는 것이다.

## 공식 문서 확인

2026-10-18 확인:
[Claude imports](https://code.claude.com/docs/en/memory),
[Claude sandbox](https://code.claude.com/docs/en/sandboxing),
[Gemini context fileName](https://geminicli.com/docs/cli/gemini-md/).
Claude 설정의 sandbox 활성화·fallback 금지는 공식 항목에 근거하되 설치 버전에서
검증되었다고 표시하지 않는다. User 설정은 조직 managed policy와 같은 강제성을
갖는다고 가정하지 않는다.

## Git 및 적용 상태

기존 미커밋 변경을 보존했다. 새 runtime 파일 3개와 새 Bats 파일은 Nix source에
포함되도록 `git add -N`만 실행했다(내용 stage/commit 아님). commit, PR, reset,
stash, 사용자 홈 activation, 실제 배포/운영 데이터/외부 리소스 변경은 수행하지 않았다.
`.github/workflows/ci.yml` 변경 없음. 작업 트리가 dirty이므로 code task Git DONE과
전체 Phase 완료는 선언하지 않는다.

## 2026-10-19 최종 보완 및 교차 검증

Codex 0.162.1 공식 permission 구현과 native probe를 대조해 custom profile에
`:minimal = read`를 추가했다. 그 결과 reviewer profile은 무해한 command를 실행하면서
workspace 밖 write를 거부하고, implementer profile은 선택한 workspace 안에서만 write
probe를 통과했다. 단순 nonzero를 sandbox PASS로 오인하지 않도록 conformance runner는
먼저 `/usr/bin/true` 성공을 요구한다.

독립 Codex review 두 차례에서 발견한 사항을 모두 반영했다.

- test-review receipt는 completion boundary가 OS 계정의 고정 trust key만 주입한다.
- retry identity는 lifecycle state에 저장되어 session 재시작으로 초기화되지 않는다.
- Stop은 BLOCKED retry identity를 회전시키지 않는다.
- Claude `PostToolUseFailure`를 shared retry budget에 연결한다.
- memory promotion은 source와 destination lock을 정렬된 순서로 함께 획득한다.
- native MCP payload의 session/tool-use ID와 canonical request hash를 correlation evidence로 사용한다.

세 번째 독립 review는 Codex account usage limit으로 중단되어 합의 완료로 처리하지 않았다.
집중 회귀 **31/31**, 전체 hooks **182/182**, guard **109/109**, lint, 두 Codex settings
sync derivation 및 aarch64-darwin Home Manager activation build는 exit 0이다. 변경된
Home Manager generation은 build만 했으며 실제 activation은 수행하지 않았다.

최종 잔여 조건은 코드 결함과 외부 조건을 구분한다.

| 상태 | 항목 | 종료 조건 |
|---|---|---|
| external gate | 운영 approval public key | 사용자가 고정 trust path provisioning을 승인하고 승인/거부 native 시험 수행 |
| provider runtime | Claude/Gemini native sandbox, hook, instruction | 인증 가능한 설치 runtime에서 부정 시험 수행; Gemini CLI deprecation/대체 provider 결정 포함 |
| provider runtime | 실제 MCP end-to-end | 허용 read call과 timeout/UNKNOWN correlation을 provider runtime에서 관찰 |
| deferred by FR-017 | memory 자동 요약·충돌·만료 | Phase 4 PRD/Acceptance Criteria 승인 후 구현; Phase 0~2 MVP 완료로 오인하지 않음 |
| review capacity | 3차 독립 재리뷰 | Codex usage limit 해제 후 blocking finding 0건 확인 |

따라서 deterministic 구현과 repository build는 통과했지만, 외부 승인·credential·provider
실행 증거가 필요한 항목까지 포함한 Phase 0~2 전체 완료는 아직 선언하지 않는다.
