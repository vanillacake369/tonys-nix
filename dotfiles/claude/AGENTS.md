# Agent Development Guide

A file for [guiding coding agents](https://agents.md/).

## 5대 핵심 원칙 (Mandatory)

1. **Zero-Inference (추론 금지)**: 논리를 추측하지 마라. 불확실하면 `grep`, `ls` 등으로 확인하거나 사용자에게 질문하라. 근거 중심의 구현이 절대 원칙이다.
2. **Reflexion Loop & Pre-mortem (자기 성찰)**: 전략 제안 후 스스로 비판하라. 이 설계가 실패할 이유 3가지(Pre-mortem)를 반드시 나열하라.
3. **Systems Thinking & Trade-off (시스템 사고)**: 로컬 수정이 전체 시스템에 미칠 영향(Ripple Effect)을 분석하라. [성능/가독성/유지보수성]의 3축으로 트레이드오프를 평가하라.
4. **Reverse-Traverse Escalation (역방향 에스컬레이션)**: 서브에이전트가 설계 결함이나 모호함을 발견하면 스스로 판단하지 말고 즉시 상위 에이전트나 사용자에게 질의하라.
5. **Multi-perspective Self-Correction (다각도 자가 교정)**: 최종 보고 전, '보안 전문가'와 '시니어 아키텍트'의 시각에서 검토하고 수정하라. (에이전트 간 토론 대신 1턴 내 수행)

## 개발 라이프사이클 (Research -> Strategy -> Execution)

### 1. Research (Fact Finding)
- **Zero-Inference**: 현재 코드 상태를 철저히 확인한다.
- **Evidence**: 분석 결과에는 반드시 관련 코드 라인이나 파일 경로를 근거로 제시한다.

### 2. Strategy (Design & Gate)
- **Pre-mortem**: 제안한 계획의 잠재적 위험 요소를 명시한다.
- **One-shot PoC (Optional)**: 리스크가 큰 작업(처음 쓰는 API 등)은 10줄 내외의 PoC와 함께 리뷰 포인트를 제시하여 사용자 승인을 받는다.
- **Decision Gate**: 전략과 트레이드오프를 보고한 뒤 사용자 컨펌을 기다린다.

### 3. Execution (Implementation & Test)
- **Requirement-Test Mapping**: 구현 전, 요구사항과 테스트 케이스를 매핑한 테이블을 작성한다.
- **Adversarial Testing**: 구현을 파괴하려는 시각에서 테스트를 설계한다. (5대 엣지 케이스: Null, Boundary, Type, State, Failure Path)
- **Validation**: 빌드 및 테스트 도구(lint, tsc 등)를 실행하여 최종 확인한다.

## 가드레일

- 빌드 호환성(babel/webpack/Node 버전) 확인 없이 패키지를 설치하지 않는다
- lock 파일(yarn.lock/package-lock.json)로 패키지 매니저를 판단한다. 추측하지 않는다
- 에이전트가 탐색 중인 파일을 메인에서 중복으로 읽지 않는다
- snapshot 테스트 업데이트(-u)를 변경 원인 파악 없이 실행하지 않는다
- 하나의 커밋에 3개 이상의 책임을 넣지 않는다
- PR 본문을 자유 형식으로 작성하지 않는다

## 오케스트레이션

### 서브에이전트 사용 기준
- 독립적 탐색이 3개 이상 → 병렬 background 에이전트
- 특정 파일 1-2개 → 직접 읽기 (에이전트보다 빠름)
- 결과가 다음 단계의 입력 → foreground (대기 필요)
- 대량 파일 분석(10+) → 서브에이전트에 위임

### 중복 방지
에이전트를 실행했으면 동일 파일을 메인에서 읽지 않는다. 에이전트 결과를 기다린 뒤 그 결과만 사용한다.

## 커밋 컨벤션

```
type(scope): description

Optional body explaining why.
```
Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## PR 본문 구조

```
## 개요
## 변경사항
## 테스트
## 논의사항
  ### 이슈 : ~~~
  ### 대안 (테이블)
  > 리뷰어 요청사항
```
