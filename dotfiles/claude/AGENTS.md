# Agent Development Guide

A file for [guiding coding agents](https://agents.md/).

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
