# Nix composition complexity — 검증

2026-11-27, 기준 `17bab767e846bb507aa0ed62c755367ec4ee8aad`.
코드 변경 전 작업 트리는 깨끗했다. 사용자 홈·시스템 활성화 및 원격 쓰기는 없었다.

## 정량 결과

| 범위·지표 | BEFORE | AFTER | 변화 |
| --- | ---: | ---: | ---: |
| 변경 대상 7개 경로 중 존재하는 코드 파일 | 7 | 3 | -4 (-57.1%) |
| 변경 대상 물리 줄 | 574 | 364 | -210 (-36.6%) |
| 변경 대상 NLOC | 465 | 285 | -180 (-38.7%) |
| 변경 대상 lambda 구분자 | 54 | 18 | -36 |
| 변경 대상 결정 토큰 | 8 | 3 | -5 |
| 최대 중첩 `if` 깊이 | 2 | 1 | -1 |
| 변경 대상 `readDir` 호출 | 3 | 1 | -2 |
| 변경 대상 `functionArgs` 호출 | 1 | 0 | -1 |
| 변경 대상 `lib.pipe` 호출 | 6 | 0 | -6 |
| 전체 추적 Nix 파일 | 72 | 68 | -4 (-5.6%) |
| 전체 추적 Nix 물리 줄 | 3,985 | 3,779 | -206 (-5.2%) |
| 전체 추적 Nix NLOC | 3,351 | 3,176 | -175 (-5.2%) |

측정은 각 파일의 Python `splitlines()` 길이와, 빈 줄 또는 왼쪽 공백 제거 후
`#`로 시작하는 줄을 제외한 줄 수를 세었다. 호출 수는 주석 줄을 제외한 문자
출현 횟수다. 대상 경로는 `design.md` §1에
명시했다. NLOC는 토큰·인지 복잡도나 실행 시간의 대리 지표가 아니다.
설치된 `lizard`는 Nix를 지원하지 않아 CCN 결과를 사용하지 않았다.
구조 지표는 `tonys-agent-harness`의 `skl-pre-nix-complexity-ljh` 측정기
(`23efdd0`)에서 `--base 17bab76`과 위 7개 경로를 지정해 다시 확인했다.
`decisions`는 파서 출력의 `if`, `assert`, `&&`, `||`, `->` 합계이며
CCN이나 인지 복잡도 점수가 아니다.

## 계약 검증

| 불변식 | 코드 근거 | 관찰·명령 | 상태·한계 |
| --- | --- | --- | --- |
| overlay 순서 | `flake.nix`의 명시적 목록 | Rust → 사전순 9개 → Neovim을 정적 확인; Python으로 9개 import와 `pkgs/*.overlay.nix`의 이름·순서 일치 확인; Darwin activation `.drv` 2개 전후 `cmp` 동일 | VERIFIED for checked derivations; 모든 플랫폼 빌드 NOT_RUN |
| check 이름과 guard 결과 | `flake.nix`, `tests/guard/overlays.test.nix` | `nix eval --offline --no-update-lock-file ...checks.aarch64-darwin --apply builtins.attrNames` 전후 `cmp` 동일; `just _test-guard` 67/67 | VERIFIED |
| 공개 Home 출력과 사용자 | `lib/mk-home-entries.nix`, `modules/language.home.nix` | 27개 출력 이름 전후 `cmp` 동일; `hm-limjihoon-aarch64-darwin`의 `home.username`·`home.homeDirectory` 동일 | VERIFIED for evaluated values |
| 패키지 결과 | `modules/language.home.nix` | `hm-limjihoon-aarch64-darwin`와 `hm-vpplab-aarch64-darwin`의 activation `.drvPath` 전후 `cmp` 동일 | VERIFIED for two Darwin targets; Linux/WSL activation NOT_RUN |
| 평면 module 발견 | `lib/discover-modules.nix`, `tests/guard/entrypoints.test.nix` | guard 67/67; `nix-instantiate --eval --strict --json` 결과의 파일 이름·순서가 평면 디렉터리의 Home Manager 22개, NixOS 11개와 일치. 임시 하위 디렉터리를 넣은 `nix-instantiate --eval --strict`가 예상 오류로 실패 | 현재 평면 구조와 nested failure VERIFIED |
| 정식 검사 | `recipes/check.just` | `just check all` exit 0: Bats 84/84, guard 67/67, lint, formatting 및 Darwin `home-activations`; 마지막 문자열 복원 뒤 `just check flake` exit 0 | VERIFIED on aarch64-darwin |
| 변경 경계 | `git diff -- flake.lock`, `git diff --check` | 둘 다 출력 없음, exit 0 | VERIFIED |

Nix 평가·check 빌드는 로컬 Nix store와 평가 캐시를 사용할 수 있다.
`nix-instantiate --eval --json`은 경로를 store 경로로 직렬화하므로 module
발견 결과는 경로의 마지막 파일 이름을 기준으로 비교했다. Gradle 설정 문자열의
주석 변경도 derivation을 바꾸는 것을 관찰해 그 변경은 복원했고, 최종 `.drvPath`
두 개가 기준값과 다시 일치함을 확인했다.
런타임 성능 개선은 측정하지 않았으며 `UNMEASURED`다. 기존 문서에 기록된
Linux NixOS Podman 옵션 실패는 이번 변경과 별개로 남아 있고, 이 작업에서는
재실행하지 않았다. 실제 호스트 적용 결과는 `UNRESOLVED`다.

## 결론

선택한 범위에서 NLOC가 38.7% 줄어 목표 20%를 넘었다. 관찰한 Darwin 출력과
정식 검사는 유지됐다. 코드 리팩터링 검증은 `VERIFIED`; 미실행 플랫폼의
활성화 동등성은 `UNRESOLVED`다.
