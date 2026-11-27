# Nix composition complexity — 설계

## 1. 현재 구조와 AS-IS 측정

기준 리비전 `17bab76`, 깨끗한 작업 트리. `flake.nix`은
`collect-flake-overlays` → `collect-overlays`를 거쳐 overlay를 로드하고,
`collect-checks` → `tests/guard.check.nix`를 거쳐 단일 guard check를 만든다.
`discover-modules`는 평면 `modules/`를 재귀 탐색한다.
`language.home.nix`의 지역 변수 `languages`에서 실제 소비자는 `packages`뿐이다.

측정 범위는 `flake.nix`, `lib/collect-flake-overlays.nix`,
`lib/collect-overlays.nix`, `lib/collect-checks.nix`, `lib/discover-modules.nix`,
`modules/language.home.nix`, `tests/guard.check.nix`의 7개 파일이다.
물리 줄 수는 `splitlines()` 길이, NLOC는 빈 줄과 `#`로 시작하는 줄을 뺀 수다.
주석이 아닌 문자열 내부의 주석·분기는 별도로 파싱하지 않는다.

| 지표 | BEFORE | AFTER | 변화 |
| --- | ---: | ---: | ---: |
| 대상 파일 | 7 | 3 | -4 (-57.1%) |
| 물리 줄 | 574 | 364 | -210 (-36.6%) |
| NLOC | 465 | 285 | -180 (-38.7%) |
| Nix 파서 기준 lambda 구분자 | 54 | 18 | -36 |
| Nix 파서 기준 결정 토큰 | 8 | 3 | -5 |
| 최대 중첩 `if` 깊이 | 2 | 1 | -1 |
| `readDir` 호출 | 3 | 1 | -2 |
| `functionArgs` 호출 | 1 | 0 | -1 |
| `lib.pipe` 호출 | 6 | 0 | -6 |
| 공개 Home Manager 출력 | 27 | 27 | 동일 |
| guard 통과 | 67/67 | 67/67 | 동일 |

전체 추적 Nix 코드에서도 72→68파일, 3,985→3,779 물리 줄,
3,351→3,176 NLOC다. 테스트 변경을 포함한 전체 수치이며 새 스펙 문서는 제외한다.
같은 정의로 기준 리비전은 `git show HEAD:<path>`, 변경 후는 작업 트리 파일을 읽었다.

`lizard`는 Nix 언어를 지원하지 않아 Nix 함수 CCN을 0으로 보고한다. 이 값을
복잡도 개선의 근거로 사용하지 않는다. 운영 시간과 메모리는 측정하지 않았으며
`UNMEASURED`다.
구조 지표는 `tonys-agent-harness`의 `skl-pre-nix-complexity-ljh` 측정기
(`23efdd0`)로 기준 리비전과 작업 트리의 동일한 7개 경로를 비교했다.
`decisions`는 Nix 파서 출력의 `if`, `assert`, `&&`, `||`, `->` 합계이며
CCN이나 인지 복잡도 점수가 아니다.

## 2. 변경 설계

- `flake.nix`: 9개 로컬 overlay를 현재 사전순으로 명시하고 Rust와 pinned Neovim을
  양 끝에 둔다. `guard-tests` derivation을 `checks`에서 직접 만든다. 단일 NixOS
  호스트 출력도 직접 선언한다.
- `lib/discover-modules.nix`: 한 번의 `readDir`에서 두 suffix 목록을 추출한다.
  하위 디렉터리가 있으면 예외를 던진다.
- `modules/language.home.nix`: `languages.<name>.packages` 대신
  `languagePackages.<name>` 목록을 둔다. `lib.attrValues`의 사전순 연결과
  패키지 값은 유지한다. 미사용 `extensions`·`format`·`lint`·`diagnose`를 제거한다.
- 삭제: `lib/collect-flake-overlays.nix`, `lib/collect-overlays.nix`,
  `lib/collect-checks.nix`, `tests/guard.check.nix`.
- `tests/guard/overlays.test.nix`: 로더 내부 구현 대신 실제 로컬 overlay 파일의
  이름·함수 형태와 역할별 패키지 계약을 확인한다.

## 3. 결정 사항과 대안

현 구조 유지는 동작 위험이 가장 낮지만 중복된 탐색과 조용한 overlay 누락이 남는다.
모든 발견을 범용 로더 하나로 합치면 파일 수는 줄어도 로더의 분기와 숨은 규칙이
늘어난다. 소수의 순서 의존 overlay와 단일 check는 명시적으로 연결하고,
여러 suite가 있는 테스트 발견과 별도 책임인 Home Manager 빌더는 유지한다.
`builtins.attrNames`의 사전순 및 overlay 순서 의미를 보존한다.

## 4. 구현 단계 및 완료 기준

| # | 단계 | 유형 | 선행 | 완료 기준 | 필수 테스트(A) |
| --- | --- | --- | --- | --- | --- |
| 1 | AS-IS 출력·지표 기록 | AFK | 없음 | 기준값과 명령 기록 | guard, 출력 이름 평가 |
| 2 | overlay/check 직접 조립 | AFK | 1 | 순서와 check 이름 유지 | overlay guard, flake check 이름 |
| 3 | 모듈 발견·언어 목록 단순화 | AFK | 2 | 동일한 모듈·패키지 결과 | 전체 guard, 대표 home 평가 |
| 4 | TO-BE 측정·회귀 검증 | AFK | 3 | NLOC 20% 이상 감소, 계약 비교 | Bats, lint, guard, flake 평가 |

통합 검증(B): 기존 flake check는 Nix store에 결과를 만들 수 있으나 홈·시스템
활성화는 하지 않는다. Linux NixOS 전체 평가의 기존 Podman 옵션 실패는 범위 밖이다.
검증 명령은 `nix eval --offline --no-update-lock-file`, `just _test-guard`,
`just test-hooks`, `just lint`를 사용한다. 실패 시 수정 범위의 커밋을 되돌리면
코드와 출력 연결을 복구할 수 있다. 적용 전이므로 호스트 롤백은 필요하지 않다.
