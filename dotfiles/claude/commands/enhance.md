코드 품질, 성능, 보안을 분석하고 개선한다

# Task
$ARGUMENTS

# Workflow

1. 보안 취약점 확인 (입력 검증, 인증, 인젝션)
2. 코드 품질 분석 (중복, 복잡도, 일관성)
3. 성능 병목 확인
4. 개선 사항을 중요도별 정렬 (Critical → High → Enhancement)
5. 구현 및 테스트

# Output

- **Critical**: 즉시 수정 필요
- **High**: 유의미한 개선
- **Enhancement**: 시간 있을 때

각 항목에 `file:line` 참조 포함. 단순 문제는 바로 수정, 복잡한 문제는 단계별 계획 제시.
