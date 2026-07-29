PR 리뷰가 쉽도록 변경사항을 파일 변화 단위로 분석하고 커밋한다

# Context

$ARGUMENTS

# Goal

리뷰어가 PR에서 변경 의도와 영향 범위를 빠르게 따라갈 수 있도록 커밋 히스토리를 설계한다.
기본은 파일별 커밋이며, 파일 하나만으로 의미가 깨지는 경우에만 작고 명확한 논리 단위로 묶는다.

# Workflow

1. `git status --short`로 작업트리 상태를 확인하고, 기존 staged 변경이 있는지 구분한다.
2. `git diff --stat`, `git diff --name-status`, `git diff -- <path>`로 파일별 변경 의도를 파악한다.
3. `git log --oneline -20`와 관련 경로의 `git log --oneline -- <path>`로 기존 커밋 메시지 스타일, type, scope를 확인한다.
4. PR 리뷰 관점의 커밋 계획을 먼저 작성한다. 각 항목에는 대상 파일, 변경 의도, 묶는 이유, 커밋 메시지 초안을 포함한다.
5. 각 커밋 전 `git reset` 또는 `git restore --staged :/`로 staging을 비운다.
6. 계획된 파일만 `git add <path>`로 stage한다. 한 파일 안에 독립 변경이 섞여 있으면 `git add -p <path>`를 사용한다.
7. `git diff --cached --stat`와 `git diff --cached`로 해당 커밋에 의도한 변경만 포함됐는지 확인한다.
8. repository hook이나 phase gate가 요구하는 verify, review, postmortem, future-research evidence가 있으면 충족 여부를 확인한다.
9. 상세 메시지로 `git commit`을 실행한다.
10. 모든 커밋 후 `git status --short`와 `git log --oneline -10`으로 결과와 남은 변경을 확인한다.

# Commit Boundary Rules

- 기본값은 파일별 커밋이다.
- 같은 파일 안에 독립적인 변경이 여러 개 있으면 hunk 단위 커밋을 고려한다.
- 다음은 별도 커밋으로 분리한다:
  - 서로 다른 provider, command, skill, spec 변경
  - 동작 변경과 단순 포맷/문구 정리
  - 정책 변경과 provider adapter 반영
  - 의존성/설정 변경
  - 테스트 또는 검증 자산이 독립적인 리뷰 포인트인 경우
- 다음은 함께 커밋할 수 있다:
  - 스펙 변경과 그 스펙을 구현하는 최소 provider adapter
  - 코드 변경과 해당 코드만 검증하는 테스트
  - 문서와 생성 산출물이 서로를 설명하며 단독 커밋 시 오해가 생기는 경우
- 한 커밋에 세 개를 넘는 책임을 넣지 않는다.
- 파일 목록이 아니라 리뷰 가능한 의도와 영향 기준으로 커밋 경계를 설명한다.

# Staging Safety

- 사용자 변경을 버리지 않는다. `git reset --hard`, `git checkout -- <path>`, `git clean`을 사용하지 않는다.
- `git reset`은 staging을 비우는 용도로만 사용한다.
- 삭제 파일은 반드시 `git status --short`와 `git diff -- <path>`로 의도된 삭제인지 확인한 뒤 stage한다.
- 기존 staged 변경이 사용자 작업일 수 있으므로, 커밋 계획에 포함하지 않을 변경은 unstaged 상태로 남긴다.
- 커밋 전마다 `git diff --cached`를 확인하지 못했으면 커밋하지 않는다.
- hook 또는 phase gate가 커밋을 차단하면 우회하지 않는다. 필요한 evidence, 실패 원인, 다음 결정을 보고한다.

# Commit Message Rules

형식은 기존 히스토리와 repository convention을 따른다.

```text
type(scope): description

Optional body explaining why.
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

- 제목은 변경 파일의 이름보다 변경 의도를 설명한다.
- 본문에는 필요할 때 다음을 포함한다:
  - 변경 전 문제
  - 이 커밋에서 바꾼 파일과 이유
  - 후속 커밋과 분리한 이유
  - 리뷰어가 확인해야 할 포인트
- 메시지는 PR에서 커밋 하나만 읽어도 해당 파일 변화의 맥락을 이해할 수 있을 만큼 구체적으로 작성한다.

# Output

마지막에 다음을 보고한다:

- 생성한 커밋 목록
- 파일별 또는 hunk별 커밋 경계
- 함께 묶은 파일이 있다면 그 이유
- 실행한 검증 명령과 결과
- 남은 uncommitted 변경 여부
