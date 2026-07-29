# Zellij 플러그인 관리

이 디렉터리는 Home Manager가 설치하는 WASM 플러그인의 목적과 제약을 기록한다.
실제 바이너리는 `modules/shell/zellij.hm.nix`에서 `fetchurl`로 고정한다.

## 채택

- `zellij-forgot`: `Alt /`에서 floating which-key 도움말로 사용한다. Plain `/`는 Zellij가 가로채지 않는다.
- `room`: 현재는 설치만 유지한다. Tab 검색은 context 기록과 unified command palette 연동을 위해 `zellij-pane-picker --tabs`를 우선 사용한다.
- `zestty`: 설치는 유지한다. `back`은 no-op 상황에서도 성공 종료할 수 있어 `Alt n`의 주 구현으로 사용하지 않는다.

## 제거 또는 보류

- `zellij-autolock`: 제거한다. Neovim/TUI 충돌은 `Ctrl` 기반 Zellij mode 진입키를 없애고, 자주 쓰는 Zellij 조작은 search/rename scope를 제외한 `Alt` direct binding으로 이동해서 해결한다.
- `harpoon`: pane을 수동 등록해야 해서 자동 fuzzy navigation 모델과 맞지 않아 제거 상태를 유지한다.
- custom Rust WASM unified navigator: Phase 1의 CLI/plugin 조합으로 command palette, current-session tab/pane 검색, session 전환은 가능하다. 모든 session의 pane까지 한 번에 focus하는 것은 공식 API와 state 수집 제약이 있어 설계 문서에만 남긴다.

## 상태 표시 제약

기본 layout은 Zellij built-in `compact`를 사용한다. 별도 `zjstatus` WASM과 custom layout은 유지하지 않는다.

Persistent status bar에서는 `zellij action ...` 명령을 실행하지 않는다. 특히 command widget에서 `list-panes --json`을 반복 호출하면 Zellij 내부에서 다시 Zellij CLI를 호출하는 구조가 되어 프로세스가 누적될 수 있다.

`LaunchOrFocusPlugin` keybind block에서 `width`, `height`, `x`, `y`는 Zellij floating pane 옵션으로 해석되지 않고 plugin configuration으로 전달된다. 따라서 `zellij-forgot` help 화면에 잘못 표시되므로 해당 키를 넣지 않는다.
