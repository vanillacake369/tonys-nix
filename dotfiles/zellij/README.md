# Zellij Navigation

이 디렉터리는 Zellij keymap, shell compatibility shim, Rust navigation runtime,
optional WASM backend를 하나의 navigation boundary로 다룬다.

## Philosophy

- Zellij은 `Alt` direct binding과 native mode를 맡고, foreground TUI는 `Ctrl`과
  plain search input을 소유한다.
- Bash는 entrypoint compatibility만 유지한다. 상태 전이, routing, validation,
  logging은 Rust runtime이 소유한다.
- Navigation state는 "현재 위치"가 아니라 "돌아갈 위치"를 기록한다. 그래서 picker
  이동과 context toggle은 같은 `previous-target` 계약을 공유한다.
- Protected client는 기본적으로 보수적으로 다룬다. Codex/CDX 같은 long-running
  client가 감지되면 same-client CLI mutation은 막고, plugin/sidecar 경로는 명시적인
  strategy일 때만 사용한다.

## Structure

- `config.kdl.base`: key namespace와 Zellij plugin wiring의 source template.
- `scripts/`: 기존 keybind와 외부 호출면을 보존하는 얇은 shell shims.
- `nav/`: Rust CLI runtime. feature slice가 model/state/policy를 모으고, outbound
  runtime이 Zellij, fzf, filesystem, shell process boundary를 담당한다.
- `nav/wasm/switcher/`: protected navigation을 위한 optional Rust WASM backend.

## Project sessions

`zellij-nav projects --json`은 중앙 `projectRoots`에 선언된 root의 직계 디렉터리를 canonical path로
중복 제거해 `path`, `display_name`, `session_name`, `connect_session_name`, `layout`
모델을 출력한다.
`ZELLIJ_REPO_ROOTS`의 colon-separated roots로 탐색 위치를 덮어쓸 수 있다. 같은
세션 이름은 유일한 정규화 basename을 그대로 사용한다. 같은 basename이 여러 roots에
중복되거나 macOS Unix socket 경로 한도를 넘는 경우에만 canonical path의 안정적인 hash
suffix를 붙인다. `repo-to`에서 basename이
중복되면 임의로 첫 항목을 고르지 않고 후보를 포함한 ambiguity error를 반환한다.
프로젝트 목록 변경으로 충돌이 사라져도 활성 hash session은 종료될 때까지 재사용하고,
새 충돌이 생겼을 때 모호한 basename session이 활성 상태라면 작업 상태가 둘로 갈라지지
않도록 자동 생성을 중단한다. 해당 session을 종료한 다음 실행하면 경로별 hash session으로
전환된다.

프로젝트별 layout은 `modules/shell/zellij.hm.nix`의 중앙 `projectLayouts` attrset에
canonical path 또는 basename key로 선언한다. 저장소 안의 설정 파일이나 명령은 읽거나
실행하지 않는다. 매핑이 없으면 JSON `layout`은 `null`이며 새 세션은 프로젝트 cwd에서
전역 `default_layout`(현재 `compact`)을 그대로 따른다.

interactive Fish에서 인자 없이 `zellij`을 실행하면 `auto-project`가 먼저 현재 cwd에
해당하는 프로젝트 하나를 고른 뒤 그 session만 생성하거나 연결한다. sibling 프로젝트는
미리 만들지 않으며, root 자체나 그 밖의 경로에서는 session을 만들지 않고 실제 Zellij의
일반 동작을 그대로 따른다.
명시적 subcommand와 option이 있는 호출도 항상 원본 Zellij으로 전달한다. 기존 Zellij
안에서 재호출하면 선택된 project session을 background로 만든 뒤 sidecar가 별도 TTY
client를 연결하며, foreground Zellij을 중첩하지 않는다. 사용자가 sidecar 명령을 직접
실행할 필요는 없다. `zellij-nav repo`와
`repo-to`는 동일한 discovery/model을 사용하는 수동 CLI fallback이다.
`Alt-s`, `r` 또는 `zellij-nav reload-projects`는 선언된 프로젝트 전체를 명시적으로
background 생성한다. 이미 실행 중인 session은 그대로 두고, attach·switch·kill은 하지
않는다. 개별 생성 실패가 있어도 나머지를 계속 처리한 뒤 실패를 모아 반환한다.

## Principles

- Feature slice는 데이터 모델과 정책을 가까이 둔다. cross-feature observation과 IO는
  outbound boundary를 통해 주입해 테스트 가능성을 유지한다.
- 상태 갱신은 짧은 filesystem lease lock 안에서 수행한다. 외부 store보다 atomic
  directory lock이 이 문제의 실패 범위를 작게 만든다.
- Helper pane은 검증된 경우에만 self-close한다. 불확실한 상황에서는 사용자 작업 pane을
  닫는 것보다 helper가 남는 편이 낫다.
- Persistent status/layout 경로에서는 Zellij CLI를 반복 호출하지 않는다. navigation
  command는 사용자의 명시적 key action에 의해 실행된다.

## Verification

주요 guardrail은 Rust unit tests, shell hook tests, generated Zellij config Nix
assertions, formatter/linter 조합으로 확인한다. WASM derivation은 빌드 시간이 길 수
있으므로 일상 검증에서는 metadata/format check를 우선하고, release artifact 검증이
필요할 때만 별도로 빌드한다.
