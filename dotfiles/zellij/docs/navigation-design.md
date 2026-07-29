# Zellij navigation design

## 현재 문제

- `zellij-autolock`이 Neovim/fzf/yazi/lazygit 입력 충돌을 우회했지만, Lock state와 AutoLock policy가 섞여 UX가 불안정했다.
- `Ctrl p`, `Ctrl t`, `Ctrl n`, `Ctrl h`, `Ctrl s`, `Ctrl o` mode 진입키가 Vim/Neovim과 충돌했다.
- 자주 쓰는 pane/tab/session 조작이 custom leader 아래에 있어 호출 비용이 높았다.
- 기존 `Alt \`` context toggle은 평소 context를 기록하는 reliable hook이 없어 첫 실행 또는 plugin picker 이동 후 동작을 보장하지 못했다.

## 선택한 구조

Phase 1은 custom WASM 없이 Zellij 공식 mode와 CLI wrapper를 조합한다.

- Direct binding: 자주 쓰는 pane/tab/session mode와 picker는 `Alt` 단일 조합으로 호출
- Native Zellij modes: 드문 관리 기능은 pane/session/resize/move/scroll mode 안에 둔다.
- Status/Layout: Zellij built-in `compact` layout
- Help: `zellij-forgot`
- Picker / command palette: `zellij-pane-picker` + `fzf`
- Navigation state: `previous-target.json`
- Previous session/context: `zellij-context-toggle` + `zellij-nav-lib`
- Previous fallback: Zellij native `focus-previous-pane`

`Alt Space`는 unified command palette direct binding으로 사용한다. macOS 터미널에서는 Option 키가 특수문자 입력으로 설정되어 있으면 `Alt Space`, `Alt /`, `Alt P/T/S`, `Alt N/n`이 Zellij까지 전달되지 않을 수 있으므로, 사용하는 터미널에서 Option/Alt를 Meta 또는 Esc prefix로 보내도록 설정해야 한다. Kitty keyboard protocol 설정은 Darwin config에서 유지해 `Alt Shift p/t/s`의 대소문자 구분을 보조한다.

`zellij-autolock`은 제거한다. 기본 상태에서 Neovim/TUI가 `Ctrl` 계열 입력을 소유하고, Zellij 조작은 `Alt` direct binding 또는 native Zellij mode 안으로 들어간다.

상시 렌더링되는 status bar는 Zellij CLI를 호출하지 않는다. built-in `compact` layout을 기본값으로 사용해 custom layout과 `zjstatus` plugin wiring을 유지하지 않는다.

## Key namespace

```text
Global
├─ Ctrl g    Lock / Unlock
├─ Alt p/P   pane mode / pane picker
├─ Alt t/T   tab mode / tab picker
├─ Alt s/S   session mode / session picker
├─ Alt Space unified command palette
├─ Alt /     floating keymap help
├─ Alt r/m/e resize / move / scroll mode
├─ Alt h/j/k/l pane focus
├─ Alt N     previous pane
├─ Alt n     previous explicit context
├─ Alt f     toggle fullscreen
├─ Alt w     toggle floating panes
├─ Alt [     previous swap layout
└─ Alt ]     next swap layout

Pane mode
├─ n/r/d     new pane / right / down
├─ x         close pane
├─ f/w       fullscreen / floating panes
└─ c         rename pane

Session mode
├─ d         detach
├─ c/p/w     configuration / plugin manager / session manager
└─ q         quit
```

제거한 충돌 키:

```text
Ctrl p  pane mode
Ctrl t  tab mode
Ctrl n  resize mode
Ctrl h  move mode
Ctrl s  scroll mode
Ctrl o  session mode
Ctrl q  quit
Alt a   autolock toggle
Enter   autolock trigger
```

자주 쓰는 조작은 prefix 없이 `Alt` 단일 조합에 둔다. 소문자는 mode, 대문자는 picker라는 규칙을 유지한다.

```text
p/P = Pane mode / Pane picker
t/T = Tab mode / Tab picker
s/S = Session mode / Session picker
```

`Alt P`, `Alt T`, `Alt S`는 터미널 입력 관점에서 `Alt Shift p/t/s`다. KDL config에는 Zellij가 dump config에서 사용하는 표기와 맞춰 `Alt Shift p/t/s`로 기록한다.

드문 관리 기능은 direct binding으로 흩뿌리지 않고 기존 Zellij mode 안에 둔다. 기본 typing surface에서는 위 `Ctrl` 키들을 Zellij가 가로채지 않는다.

## Search 범위

현재 구현은 공식 CLI가 안정적으로 제공하는 범위를 따른다.

- `--tabs`: 현재 session tab 검색
- `--panes`: 현재 session pane 검색
- `--sessions`: 실행 중인 session 검색
- `--all`: command + session + current-session tab/pane 통합 목록

`Alt Space`는 unified command palette를 연다. 현재 palette에 포함된 command는 새 pane, fullscreen, floating, swap layout, session manager, lock, detach처럼 이름만으로 즉시 실행 가능한 action으로 제한한다. `rename`처럼 추가 입력이 필요한 command는 shell wrapper에서 안정적인 interactive prompt를 제공하기 전까지 넣지 않는다.

Direct binding은 `normal`, `pane`, `tab`, `resize`, `move`, `session`에서 동작하고 `locked`, `scroll`, `search`, `entersearch`, `renametab`, `renamepane`에서는 제외한다. 따라서 plain `/`는 shell, Neovim, fzf 검색 입력으로 그대로 전달되고, `Alt /`만 help plugin을 연다. Darwin config의 기존 `Ctrl /` unbind는 유지하지만, 이는 `Alt /`와 별개다.

모든 session의 tab/pane을 한 번에 나열하고 특정 pane까지 focus하는 기능은 보류한다. Zellij 0.44.3 CLI는 현재 session의 pane/tab 조회와 `switch-session --pane-id`를 제공하지만, 실행 중인 모든 session의 pane 목록을 하나의 명령으로 안정적으로 수집하는 공식 CLI는 없다.

## Previous session/context

`Alt N`은 Zellij native `FocusPreviousPane`에 직접 연결한다. 이 경로는 Zellij 내부 focus history를 사용하므로 shell wrapper보다 빠르고 정확하다.

`Alt n`는 `zellij-context-toggle` wrapper를 호출해 explicit session/context toggle을 수행한다.

처음에는 `Alt Shift \``를 사용했지만, WezTerm/macOS/한국어 입력 보정 조합에서 grave 계열 키는 문자 합성 경로를 타기 쉬워 Zellij의 `Alt Shift \`` key event로 안정적으로 보존되지 않았다. 이후 `Alt g`와 `Alt 6`도 실제 runtime toggle 실패 보고 후 폐기했다. `Alt n`은 Neovim alternate-file 계열 사용감에서 영감을 받은 단일 direct key이며, repo 기준 Zellij/Fish/fzf/사용자 Neovim keymap과 중복이 없다. Shift와 grave/dead-key 경로를 피하고 native previous pane의 `Alt N`과 의미적으로 짝을 이룬다.

`Alt n`는 floating `Run` helper로 실행된다. Zellij가 helper pane에 focus를 넘기면 현재 위치 캡처가 helper 자신을 제외한 focused terminal pane을 찾지 못해 session target으로 degrade할 수 있다. Toggle helper는 사용자 입력을 받지 않는 단발성 명령이므로, keybind가 `ZELLIJ_NAV_FOCUS_UNDERLYING=1` marker를 넘긴 경우에만 실행 직후 native `focus-previous-pane`을 한 번 호출해 helper가 열리기 직전의 underlying pane을 다시 focus한 뒤 현재 target을 캡처한다. 이 보정은 picker에는 적용하지 않는다. Picker는 `fzf` 입력을 받아야 하므로 helper focus를 유지해야 한다.

상태 파일은 하나만 사용한다.

```text
~/.local/state/zellij-workspace/previous-target.json
```

`previous-target.json`은 "현재 위치"가 아니라 "돌아갈 위치"만 저장한다. 이전 구현의 `previous-context.json`, `current-context.json`, `previous-session`, `current-session`은 시작 시 자동 삭제한다.

상태 전이:

```text
Picker selects target B while currently at A

A captured
  -> previous-target = A
  -> focus B

Alt n

previous-target = A
current = B
  -> validate A
  -> focus A
  -> previous-target = B
```

복원 순서:

```text
pane target valid
  -> switch session with pane id

pane missing, tab valid
  -> switch session
  -> focus tab

tab missing, session valid
  -> switch session

session missing
  -> delete previous-target
  -> no-op
```

Cross-session restore는 floating helper 내부의 `list-sessions (current)` 관측값으로 post-confirm하지 않는다. `switch-session` 이후 helper process는 여전히 기존 session에 속해 있어 CLI가 old session을 current로 보고 false negative를 만들 수 있다. 대신 target session/tab/pane 존재 여부를 switch 전에 확인하고, `switch-session` action이 성공하면 movement accepted로 처리한다. 같은 session 안의 pane/tab focus는 기존처럼 확인한다.

## ADR: in-client switch-session boundary

결정: `Alt Shift p/t/s`, `Alt Space`, picker 선택, `Alt n` context toggle은 현재 Zellij client 안에서 Zellij action을 사용한다. 외부 terminal app을 열거나 `zellij attach <session>`로 새 client를 만들지 않는다.

이유: 목표 UX는 같은 터미널 client 안에서 pane/tab/session을 이동하는 것이다. 이전 외부 client 방식은 long-running agent pane을 보호하는 보수적 우회였지만, 새 terminal window/tab을 여는 부작용이 크다. 따라서 navigation boundary를 `zellij-nav-lib` 하나로 되돌린다. Helper pane 자체는 `close_on_exit true`로 Zellij가 닫게 하고, 실제 session/pane 이동은 helper 종료 이후 짧게 지연된 dispatcher에서 수행한다. 이렇게 하면 helper 종료와 target focus가 같은 tick에 겹치지 않아 focused target pane이 닫히는 위험을 줄이면서, 종료된 floating helper pane이 남는 문제도 피한다. `ZELLIJ_NAV_HELPER=1`로 표시된 helper 자신의 `ZELLIJ_PANE_ID`를 닫는 trap은 기존/예외 경로용 보조 fallback으로만 남긴다.

유지하는 것:

- 현재 session의 pane/tab picker와 command palette 실행은 기존 floating picker UX를 유지하되, navigation action이 close-on-exit lifecycle과 겹치지 않게 한다.
- `previous-target.json` 상태 계약은 유지한다.
- cross-session 이동 전 return target을 기록하므로 `Alt n` 반환 경로를 이어갈 수 있다.
- pane target은 가능하면 `switch-session --pane-id`, tab target은 target session의 tab focus 후 `switch-session`, session target은 `switch-session`으로 처리한다.

trade-off:

- `close_on_exit true`가 helper 종료를 담당하므로 target 전환은 반드시 dispatcher에서 지연 실행해야 한다. 전환을 helper 프로세스 안으로 다시 넣으면 Zellij가 현재 focused target pane을 닫는 회귀가 생길 수 있다.
- 실제 focus/switch는 dispatcher가 지연 실행하므로 선택 후 이동까지 약 0.12초의 의도적인 지연이 있다.
- Zellij CLI는 helper process 관점의 current session 관측이 늦을 수 있으므로, cross-session 이동은 switch 전 target 존재 확인과 `switch-session` action 성공 여부까지만 자동 검증한다.
- Zellij global keybind에서 helper pane 없이 현재 focused pane의 controlling TTY에 직접 fzf UI를 띄우는 공식 CLI 경로는 확인되지 않았다.

`zestty back`은 no-op 상황에서도 성공 종료할 수 있어 이 keybind의 주 경로로 사용하지 않는다.

`zellij-pane-picker --sessions` 또는 unified command palette에서 session을 선택하면 선택 직전 context를 `previous-target.json`에 저장한다. 이후 `Alt n`는 직전 target으로 이동하고, 다시 누르면 현재 target과 직전 target을 맞바꾼다.

Zellij built-in session-manager는 선택 이후 plugin 내부에서 session switch를 수행하므로 선택 시점에 wrapper가 개입할 수 없다. 따라서 command palette의 `[CMD] Session manager`와 기존 session mode의 `w`는 session-manager를 열기 직전에 현재 context를 먼저 기록한다. 사용자가 session-manager에서 다른 session으로 이동하면 `Alt n`가 이 기록으로 돌아오고, session-manager를 취소하면 다음 toggle은 현재 target과 동일한 기록을 감지해 no-op으로 정리한다.

제약:

- 따라서 모든 수동 pane 이동까지 포함한 완전한 전역 MRU는 shell wrapper만으로 보장하지 않는다.
- 같은 session 안의 즉시 pane toggle은 direct `Alt \``를 사용한다.
- session list ordering에서 "이전 session"을 추론하지 않는다. 기록된 previous target이 없으면 no-op이다.

완전한 session/tab/pane MRU가 필요하면 Phase 2에서 Zellij plugin event를 구독하는 작은 WASM navigator를 설계해야 한다.

helper pane 없이 preview UI와 session switch를 모두 Zellij 내부에서 처리하려면 Phase 2 후보는 두 가지다.

- shell prompt 전용 direct TTY picker: 현재 shell prompt에서만 `fzf </dev/tty >/dev/tty`를 실행한다. Neovim/Codex 같은 foreground TUI에 무단 주입하지 않는다.
- Rust/WASM Zellij plugin navigator: Zellij plugin API로 UI 렌더링과 `switch_session` action을 같은 plugin lifecycle에서 처리한다.

## Rollback

1. `config.kdl.base`에서 direct binding block을 이전 revision으로 되돌린다.
2. `zellij-autolock`을 다시 쓰려면 plugin alias, `load_plugins`, Home Manager fetchurl을 복원한다.
3. `zellij-pane-picker`/`zellij-context-toggle` 변경을 이전 revision으로 되돌린다.
4. 이번 in-client session switch만 되돌리려면 `Alt Shift s`/`Alt n` binding과 `zellij-nav-lib` navigation helper 변경을 이전 revision으로 되돌린다.
5. `home-manager switch`를 실행하기 전이라면 git diff만 되돌리면 된다.
