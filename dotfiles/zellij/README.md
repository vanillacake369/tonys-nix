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
