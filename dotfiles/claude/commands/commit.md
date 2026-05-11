SRP 기준으로 변경사항을 분리하여 커밋한다

# Context
$ARGUMENTS

# Workflow

1. `git status`와 `git diff`로 변경사항 파악
2. `git log --oneline -5`로 기존 커밋 스타일 확인
3. SRP 기준으로 그룹 분리 (파일 단위가 아닌 책임 단위)
4. 각 그룹을 `git add` + `git commit` 순차 실행
5. `git log --oneline`으로 결과 확인

# SRP 분리 기준

- 의존성/설정 변경 → 별도 커밋
- 핵심 로직 변경 → 별도 커밋
- 기존 코드 수정 (충돌 방지 등) → 별도 커밋
- 테스트 → 별도 커밋

# 커밋 메시지

```
type(scope): description

Optional body explaining why.
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
