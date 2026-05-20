# Agent Development Guide

A file for [guiding coding agents](https://agents.md/).

## 5대 핵심 원칙 (Mandatory)

1. **Zero-Inference (추론 금지)**: 논리를 추측하지 마라. 불확실하면 즉시 중단하고 질문하라.
2. **Reflexion & Pre-mortem (자가 비판)**: 전략 수립 후 "왜 실패할 것인가?" 시나리오 3개를 반드시 작성하라.
3. **Systems Thinking (시스템 사고)**: 로컬 수정의 Ripple Effect와 [성능/가독성/유지보수] 트레이드오프를 분석하라.
4. **Reverse-Traverse (역방향 에스컬레이션)**: 설계 결함 발견 시 하위 에이전트는 즉시 작업을 멈추고 상위로 보고하라.
5. **Live Verification (실제 확인)**: "완료"라고 말하기 전, 반드시 실제 실행 결과(로그, 캡처 등)로 기능 동작을 증명하라.

## 개발 라이프사이클 (Phase-Locked Workflow)

**모든 응답은 반드시 최상단에 `[PHASE: 현재단계] [TURN: 0/25]`를 명시해야 한다.**

### Phase 1: RESEARCH (현황 파악 및 도구 탐색)
- **Zero-Inference**: 현재 코드 상태를 철저히 확인한다.
- **Local Protocol Alignment**: 루트에서 `justfile`, `Makefile` 등을 자동 탐색하고, 발견 시 직접 명령 대신 정의된 태스크(`just <task>`)를 최우선으로 사용한다.
- **Security Path Guard**: `.env`, `secrets/*` 등 민감 파일 접근 전 반드시 사용자에게 경고하고 승인을 획득한다.

### Phase 2: STRATEGY (전략 수립)
- **Action**: 분석 결과를 바탕으로 설계안, 트레이드오프, Pre-mortem을 작성한다.
- **[CRITICAL GATE]**: 전략 보고 후 **사용자의 명시적 승인(예: "진행하세요")이 있기 전까지는 어떠한 파일 수정도 수행하지 마라.**

### Phase 3: EXECUTION (구현 및 검증)
- **Action**: 승인된 전략에 따라 구현한다.
- **Semantic/Health Check**: 수정된 언어에 따라 다음 명령을 반드시 수행한다.
  - **Nix**: `nix flake check`
  - **K8s/Helm**: `helm lint`
  - **Terraform**: `terraform validate`
- **Integration Oracle**: 실제 환경에서 전체 기능을 통합 실행하여 동작 여부를 확인한다.
- **Documentation-as-Code**: 세션 종료 직전, 구현된 기능에 맞춰 `docs/`, `README.md`, `CLAUDE.md`를 동기화한다.

### Phase 4: REPORT & EXIT (세션 종료)
- **Session Post-Mortem**: 세션 종료 시 `AGENT_REPORT.md`에 다음 내용을 기록한다.
  - `[Provider / Session Hash / New Rules / Discovered Bugs / Dependencies]`
- **Context Threshold**: Turn 횟수가 20~25회에 도달하면 상태 요약 후 세션 재시작을 사용자에게 권장한다.

## 가드레일

- 빌드 호환성(babel/webpack/Node 버전) 확인 없이 패키지를 설치하지 않는다
- lock 파일(yarn.lock/package-lock.json)로 패키지 매니저를 판단한다. 추측하지 않는다
- 에이전트가 탐색 중인 파일을 메인에서 중복으로 읽지 않는다
- snapshot 테스트 업데이트(-u)를 변경 원인 파악 없이 실행하지 않는다
- 하나의 커밋에 3개 이상의 책임을 넣지 않는다
- PR 본문을 자유 형식으로 작성하지 않는다

## 오케스트레이션 (Technique Library & Recipe)

### 1. Atomic Techniques
- **Zero-Inference**: `grep_search` + `read_file` 기반 사실 확인.
- **Pre-mortem**: 설계 결함 시나리오 3선.
- **Adversarial-Audit**: 구현을 파괴하려는 시도 기반의 테스트 설계.

### 2. Workflow Recipes
- **Feature Implementation**: `architectural-planning` + `Systems-Thinking` + `Integration-Oracle`.
- **Bug Fixing**: `codebase-investigator` + `Zero-Inference` + `Root-Cause-Analysis`.
- **System Refactoring**: `architectural-planning` + `Pre-mortem` + `nix-flake-check`.
