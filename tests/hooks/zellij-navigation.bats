#!/usr/bin/env bats
# Zellij navigation helper lifecycle tests with stubbed zellij/fzf commands.

setup_file() {
  cargo build --manifest-path "$BATS_TEST_DIRNAME/../../dotfiles/zellij/nav/Cargo.toml"
  export ZELLIJ_NAV_TEST_BIN="$BATS_TEST_DIRNAME/../../dotfiles/zellij/nav/target/debug/zellij-nav"
}

setup() {
  WORK=$(mktemp -d)
  export TMPDIR="$WORK/tmp"
  mkdir -p "$TMPDIR" "$WORK/bin" "$WORK/state"
  export ZELLIJ_NAV_STATE_DIR="$WORK/state"
  export ZELLIJ_STUB_LOG="$WORK/zellij.log"
  export ZELLIJ_STUB_LAYOUT_COPY="$WORK/sidecar-layout.kdl"
  export ZELLIJ_STUB_START_ATTACHED_FILE="$WORK/start-attached"
  export ZELLIJ_NAV_COMMAND="$ZELLIJ_NAV_TEST_BIN"

  PICKER="$BATS_TEST_DIRNAME/../../dotfiles/zellij/scripts/zellij-pane-picker"
  TOGGLE="$BATS_TEST_DIRNAME/../../dotfiles/zellij/scripts/zellij-context-toggle"
  DIAGNOSE="$BATS_TEST_DIRNAME/../../dotfiles/zellij/scripts/zellij-nav-diagnose-context"
  SIDECAR="$BATS_TEST_DIRNAME/../../dotfiles/zellij/scripts/zellij-nav-sidecar"
  PLUGIN_SWITCH="$BATS_TEST_DIRNAME/../../dotfiles/zellij/scripts/zellij-nav-plugin-switch"

  cat >"$WORK/bin/zellij" <<'EOF'
#!/usr/bin/env bash
printf 'zellij %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"

session="${ZELLIJ_SESSION_NAME:-current}"
if [ "${1:-}" = "--session" ]; then
  session="$2"
  shift 2
fi

if [ "${1:-}" = "list-sessions" ]; then
  cat <<'SESSIONS'
current [Created 1s ago] (current)
target [Created 1s ago]
old EXITED
SESSIONS
  exit 0
fi

if [ "${1:-}" = "action" ] && [ "${2:-}" = "list-panes" ]; then
  if [ "${ZELLIJ_STUB_HELPER_SELF:-0}" = "1" ]; then
    cat <<JSON
[
  {
    "id": 42,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "zellij-context-toggle",
    "pane_command": "zellij-context-toggle",
    "terminal_command": "zellij-context-toggle",
    "pane_cwd": "/tmp",
    "is_focused": true,
    "is_floating": true,
    "is_plugin": false,
    "is_selectable": true,
    "exited": true
  },
  {
    "id": 7,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "underlying",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/work",
    "is_focused": false,
    "is_floating": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    exit 0
  fi

  if [ "${ZELLIJ_STUB_PROTECTED_SELF:-0}" = "1" ]; then
    cat <<JSON
[
  {
    "id": 1,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "codex",
    "pane_command": "codex",
    "terminal_command": "codex",
    "pane_cwd": "/work",
    "is_focused": true,
    "is_floating": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    exit 0
  fi

  if [ "${ZELLIJ_STUB_PROTECTED_TERMINAL_COMMAND:-0}" = "1" ]; then
    cat <<JSON
[
  {
    "id": 1,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "sleep 1",
    "pane_command": "sleep 1",
    "terminal_command": "cdx",
    "pane_cwd": "/work",
    "is_focused": false,
    "is_floating": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 2,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "zellij-pane-picker",
    "pane_command": "zellij-pane-picker",
    "terminal_command": "zellij-pane-picker",
    "pane_cwd": "/tmp",
    "is_focused": true,
    "is_floating": true,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    exit 0
  fi

  if [ "${ZELLIJ_STUB_MULTI_FOCUS:-0}" = "1" ]; then
    cat <<JSON
[
  {
    "id": 7,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "other-focused",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/other",
    "is_focused": true,
    "is_floating": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 9,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "self",
    "pane_command": "codex",
    "terminal_command": "codex",
    "pane_cwd": "/self",
    "is_focused": true,
    "is_floating": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    exit 0
  fi

  if [ "${ZELLIJ_STUB_HELPER_FOCUS:-0}" = "1" ]; then
    if grep -q "zellij action focus-previous-pane" "${ZELLIJ_STUB_LOG:?}" 2>/dev/null; then
      cat <<JSON
[
  {
    "id": 42,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "helper",
    "pane_command": "zellij-context-toggle",
    "terminal_command": "zellij-context-toggle",
    "pane_cwd": "/tmp",
    "is_focused": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 7,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "underlying",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/work",
    "is_focused": true,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    else
      cat <<JSON
[
  {
    "id": 42,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "helper",
    "pane_command": "zellij-context-toggle",
    "terminal_command": "zellij-context-toggle",
    "pane_cwd": "/tmp",
    "is_focused": true,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 7,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "underlying",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/work",
    "is_focused": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    fi
    exit 0
  fi

  if [ "${ZELLIJ_STUB_HELPER_FOCUS_WITH_UNFOCUSED_CDX:-0}" = "1" ]; then
    if grep -q "zellij action focus-previous-pane" "${ZELLIJ_STUB_LOG:?}" 2>/dev/null; then
      cat <<JSON
[
  {
    "id": 42,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "helper",
    "pane_command": "zellij-context-toggle",
    "terminal_command": "zellij-context-toggle",
    "pane_cwd": "/tmp",
    "is_focused": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 7,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "underlying",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/work",
    "is_focused": true,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 9,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "cdx",
    "pane_command": "cdx",
    "terminal_command": "cdx",
    "pane_cwd": "/work",
    "is_focused": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    else
      cat <<JSON
[
  {
    "id": 42,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "helper",
    "pane_command": "zellij-context-toggle",
    "terminal_command": "zellij-context-toggle",
    "pane_cwd": "/tmp",
    "is_focused": true,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 7,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "underlying",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/work",
    "is_focused": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  },
  {
    "id": 9,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "cdx",
    "pane_command": "cdx",
    "terminal_command": "cdx",
    "pane_cwd": "/work",
    "is_focused": false,
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
    fi
    exit 0
  fi

  floating_self=false
  [ "${ZELLIJ_STUB_FLOATING_SELF:-0}" = "1" ] && floating_self=true
  cat <<JSON
[
  {
    "id": 1,
    "tab_id": 0,
    "tab_name": "Main",
    "title": "${session}-shell",
    "pane_command": "bash",
    "terminal_command": "bash",
    "pane_cwd": "/tmp",
    "is_focused": true,
    "is_floating": ${floating_self},
    "is_plugin": false,
    "is_selectable": true,
    "exited": false
  }
]
JSON
  exit 0
fi

if [ "${1:-}" = "action" ] && [ "${2:-}" = "list-tabs" ]; then
  printf '[{"tab_id":0,"position":0,"name":"Main"},{"tab_id":9,"position":1,"name":"Second"}]\n'
  exit 0
fi

if [ "${1:-}" = "action" ] && [ "${2:-}" = "list-clients" ]; then
  if [ "$session" = "target" ]; then
    if [ -f "${ZELLIJ_STUB_START_ATTACHED_FILE:?}" ]; then
      cat <<'CLIENTS'
CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND
2         terminal_99    zellij attach target
CLIENTS
    else
      cat <<'CLIENTS'
CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND
CLIENTS
    fi
    exit 0
  fi
  if [ "${ZELLIJ_STUB_PROTECTED_SELF:-0}" = "1" ]; then
    cat <<'CLIENTS'
CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND
1         terminal_1     codex -s danger-full-access -a never
CLIENTS
  else
    cat <<'CLIENTS'
CLIENT_ID ZELLIJ_PANE_ID RUNNING_COMMAND
1         terminal_1     bash
CLIENTS
  fi
  exit 0
fi

if [ "${1:-}" = "action" ] && [ "${2:-}" = "dump-screen" ]; then
  printf 'preview for %s\n' "$session"
  exit 0
fi

if [ "${1:-}" = "action" ]; then
  if [ "${2:-}" = "start-or-reload-plugin" ]; then
    if [ "${ZELLIJ_STUB_PLUGIN_FAIL:-0}" = "1" ]; then
      printf 'stub plugin failed\n' >&2
      exit 1
    fi
    printf 'plugin_55\n'
  fi
  exit 0
fi

exit 0
EOF
  chmod +x "$WORK/bin/zellij"

cat >"$WORK/bin/wezterm" <<'EOF'
#!/usr/bin/env bash
printf 'wezterm %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"

write_sidecar_status_from_layout_args() {
  layout=""
  prev=""
  for arg in "$@"; do
    if [ "$prev" = "--new-session-with-layout" ]; then
      layout="$arg"
      break
    fi
    prev="$arg"
  done
  if [ -n "$layout" ] && [ -f "$layout" ]; then
    cp "$layout" "${ZELLIJ_STUB_LAYOUT_COPY:?}"
    status_file="$(awk -F '"' '/args "--runner"/ { print $6; exit }' "$layout")"
    [ -n "$status_file" ] && printf 'ok\n' > "$status_file"
  fi
}

if [ "${1:-}" = "cli" ] && [ "${2:-}" = "spawn" ]; then
  if [ "${ZELLIJ_STUB_WEZTERM_CLI_FAIL:-0}" = "1" ]; then
    printf 'stub cli spawn failed\n' >&2
    exit 1
  fi
  previous=""
  for arg in "$@"; do
    if [ "$previous" = "attach" ] && [ "$arg" = "target" ]; then
      touch "${ZELLIJ_STUB_START_ATTACHED_FILE:?}"
      break
    fi
    previous="$arg"
  done
  write_sidecar_status_from_layout_args "$@"
  printf '99\n'
  exit 0
fi

if [ "${1:-}" = "start" ]; then
  prev=""
  status_file=""
  for arg in "$@"; do
    if [ "$prev" = "zellij-nav-attach" ]; then
      status_file="$arg"
      break
    fi
    prev="$arg"
  done
  [ -n "$status_file" ] && printf 'ok\n' > "$status_file"
  touch "${ZELLIJ_STUB_START_ATTACHED_FILE:?}"
  exit 0
fi

exit 1
EOF
  chmod +x "$WORK/bin/wezterm"

  cat >"$WORK/bin/fzf" <<'EOF'
#!/usr/bin/env bash
awk -F '\t' '$2 == "session" && $3 == "target" { print; found = 1; exit } END { exit found ? 0 : 1 }'
EOF
  chmod +x "$WORK/bin/fzf"

  export PATH="$WORK/bin:$PATH"
  export ZELLIJ_SESSION_NAME="current"
  export ZELLIJ_NAV_DEFER_DELAY="0"
}

teardown() { rm -rf "$WORK"; }

wait_for_log() {
  local pattern="$1"
  local log="$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  local attempts=0
  while [ "$attempts" -lt 50 ]; do
    if [ -f "$log" ] && grep -q "$pattern" "$log"; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 0.05
  done
  [ -f "$log" ] && cat "$log" >&2
  return 1
}

write_previous_target() {
  cat >"$ZELLIJ_NAV_STATE_DIR/previous-target.json" <<'JSON'
{"kind":"session","session":"target","tab_id":null,"pane_id":null,"label":"target"}
JSON
}

@test "helper picker navigates synchronously even when ZELLIJ_PANE_ID is absent" {
  run env -u ZELLIJ_PANE_ID ZELLIJ_NAV_HELPER=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "picker navigation completed"
  run grep -q "deferred navigation scheduled" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
  run grep -q "close-pane" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "helper context toggle runs synchronously even when ZELLIJ_PANE_ID is absent" {
  write_previous_target

  run env -u ZELLIJ_PANE_ID ZELLIJ_NAV_HELPER=1 bash "$TOGGLE"
  [ "$status" -eq 0 ]

  wait_for_log "toggle swapped previous-target"
  run grep -q "deferred toggle scheduled" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
  run grep -q "close-pane" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "context toggle delegates full helper lifecycle to installed rust command" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
exit 0
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env \
    ZELLIJ_PANE_ID=42 \
    ZELLIJ_NAV_HELPER=1 \
    ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" \
    ZELLIJ_STUB_HELPER_SELF=1 \
    bash "$TOGGLE"
  [ "$status" -eq 0 ]

  run grep -q "rust context-toggle-run" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij --session current action close-pane --pane-id terminal_42" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "picker wrapper delegates to installed rust command when available" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
exit 0
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  run grep -q "rust picker-run --sessions" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij action switch-session target" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "picker run uses rust core when configured" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
case "$1" in
  picker-run)
    exit 0
    ;;
esac
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_NAV_PICKER_COMMAND="$WORK/bin/zellij-nav" \
    ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  run grep -q "rust picker-run --sessions" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "picker command dispatch delegates to rust run when configured" {
  cat >"$WORK/bin/fzf" <<'EOF'
#!/usr/bin/env bash
awk -F '\t' '$2 == "command" && $6 == "new-pane" { print; found = 1; exit } END { exit found ? 0 : 1 }'
EOF
  chmod +x "$WORK/bin/fzf"

  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
case "$1" in
  picker-run)
    exit 0
    ;;
esac
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" \
    bash "$PICKER" --commands
  [ "$status" -eq 0 ]

  run grep -q "rust picker-run --commands" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij action new-pane" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "picker render preview uses rust core when configured" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
if [ "$1" = "picker-preview" ]; then
  printf 'preview from rust\n'
fi
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env \
    ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" \
    bash "$PICKER" --render-preview session target - - - target
  [ "$status" -eq 0 ]
  [ "$output" = "preview from rust" ]

  run grep -q "rust picker-preview session target - - - target" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "session manager wrapper delegates to installed rust command when available" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
exit 0
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" \
    bash "$PICKER" --session-manager
  [ "$status" -eq 0 ]

  run grep -q "rust picker-command session-manager" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij action launch-or-focus-plugin --floating --move-to-focused-tab zellij:session-manager" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "session manager helper command closes its floating launcher pane" {
  run env \
    ZELLIJ_PANE_ID=42 \
    ZELLIJ_NAV_HELPER=1 \
    ZELLIJ_STUB_HELPER_SELF=1 \
    bash "$PICKER" --session-manager
  [ "$status" -eq 0 ]

  wait_for_log "command executed command_id=session-manager"
  wait_for_log "closing helper pane session=current pane=terminal_42"
  wait_for_log "closed helper pane session=current pane=terminal_42"
  run grep -q "zellij action launch-or-focus-plugin --floating --move-to-focused-tab zellij:session-manager" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij --session current action close-pane --pane-id terminal_42" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "diagnose context uses installed rust command when available" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
printf 'rust diagnose output\n'
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" bash "$DIAGNOSE"
  [ "$status" -eq 0 ]
  [ "$output" = "rust diagnose output" ]

  run grep -q "rust diagnose" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "plugin switch uses installed rust command when available" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
printf 'rust plugin output\n'
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" bash "$PLUGIN_SWITCH" target tab 9 ""
  [ "$status" -eq 0 ]
  [ "$output" = "rust plugin output" ]

  run grep -q "rust plugin-switch target tab 9" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "sidecar validates target through installed rust command when available" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
printf 'route=cli-spawn session=%s kind=%s tab=%s pane=%s\n' "$2" "$3" "$4" "$5"
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" bash "$SIDECAR" target pane 0 7
  [ "$status" -eq 0 ]

  run grep -q "rust sidecar-run target pane 0 7" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "zellij --session target action focus-pane-id terminal_7" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "sidecar stops before effects when rust target validation fails" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
printf 'invalid pane id: %s\n' "$5" >&2
exit 64
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" bash "$SIDECAR" target pane 0 7
  [ "$status" -eq 64 ]

  run grep -q "rust sidecar-run target pane 0 7" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "zellij --session target action focus-pane-id" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "sidecar propagates rust launch failure without bash fallback" {
  cat >"$WORK/bin/zellij-nav" <<'EOF'
#!/usr/bin/env bash
printf 'rust %s\n' "$*" >>"${ZELLIJ_STUB_LOG:?}"
printf 'launch failed\n' >&2
exit 1
EOF
  chmod +x "$WORK/bin/zellij-nav"

  run env ZELLIJ_NAV_COMMAND="$WORK/bin/zellij-nav" bash "$SIDECAR" target pane 0 7
  [ "$status" -eq 1 ]

  run grep -q "rust sidecar-run target pane 0 7" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "legacy focus-underlying context toggle is treated as helper" {
  write_previous_target

  run env ZELLIJ_PANE_ID=20 ZELLIJ_NAV_FOCUS_UNDERLYING=1 bash "$TOGGLE"
  [ "$status" -eq 0 ]

  wait_for_log "toggle helper inferred reason=legacy-focus-underlying-marker"
  wait_for_log "toggle swapped previous-target"
  run grep -q "deferred toggle scheduled" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
}

@test "legacy floating picker is treated as helper" {
  run env ZELLIJ_PANE_ID=1 ZELLIJ_STUB_FLOATING_SELF=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "picker helper inferred reason=legacy-floating-pane"
  wait_for_log "picker navigation completed"
  run grep -q "deferred navigation scheduled" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
}

@test "helper context toggle focuses underlying pane before capture" {
  write_previous_target

  run env ZELLIJ_PANE_ID=42 ZELLIJ_NAV_HELPER=1 ZELLIJ_NAV_FOCUS_UNDERLYING=1 ZELLIJ_STUB_HELPER_FOCUS=1 bash "$TOGGLE"
  [ "$status" -eq 0 ]

  wait_for_log "underlying pane focused for capture self_pane=42"
  wait_for_log "toggle swapped previous-target"
  run grep -q "zellij action focus-previous-pane" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run jq -e '.kind == "pane" and .session == "current" and .pane_id == 7' "$ZELLIJ_NAV_STATE_DIR/previous-target.json"
  [ "$status" -eq 0 ]
}

@test "helper context toggle ignores unfocused cdx panes in same session" {
  write_previous_target

  run env \
    ZELLIJ_PANE_ID=42 \
    ZELLIJ_NAV_HELPER=1 \
    ZELLIJ_NAV_FOCUS_UNDERLYING=1 \
    ZELLIJ_NAV_PROTECTED_STRATEGY=plugin \
    ZELLIJ_STUB_HELPER_FOCUS_WITH_UNFOCUSED_CDX=1 \
    bash "$TOGGLE"
  [ "$status" -eq 0 ]

  wait_for_log "underlying pane focused for capture self_pane=42"
  wait_for_log "toggle swapped previous-target"
  run grep -q "protected context detected route=plugin" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
  run grep -q "zellij action switch-session target" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij action start-or-reload-plugin" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "protected helper context toggle falls back from plugin to sidecar" {
  write_previous_target

  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_NAV_HELPER=1 \
    ZELLIJ_NAV_PROTECTED_STRATEGY=plugin-sidecar \
    ZELLIJ_NAV_PLUGIN_SWITCH_COMMAND="$PLUGIN_SWITCH" \
    ZELLIJ_NAV_SIDECAR_COMMAND="$SIDECAR" \
    ZELLIJ_STUB_PROTECTED_SELF=1 \
    ZELLIJ_STUB_PLUGIN_FAIL=1 \
    bash "$TOGGLE"
  [ "$status" -eq 0 ]

  wait_for_log "protected context detected route=plugin-sidecar"
  wait_for_log "plugin navigation failed reason=command-failed"
  wait_for_log "protected fallback starting from=plugin to=sidecar"
  wait_for_log "sidecar navigation accepted session=target"
  wait_for_log "protected fallback completed route=sidecar"
  wait_for_log "toggle swapped previous-target"
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "navigation log rotates when threshold is exceeded" {
  printf 'already too large\n' > "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"

  run env \
    ZELLIJ_NAV_LOG_ROTATE_BYTES=8 \
    ZELLIJ_NAV_LOG_ROTATE_FILES=2 \
    ZELLIJ_PANE_ID=1 \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  [ -f "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log.1" ]
  run grep -q "already too large" "$ZELLIJ_NAV_STATE_DIR"/zellij-navigation.log.*
  [ "$status" -eq 0 ]
  wait_for_log "picker navigation completed"
}

@test "non-helper picker keeps synchronous navigation path" {
  run env ZELLIJ_PANE_ID=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "picker navigation completed"
  run grep -q "deferred navigation scheduled" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
}

@test "non-helper current target prefers its own pane id over other focused clients" {
  run env ZELLIJ_PANE_ID=9 ZELLIJ_STUB_MULTI_FOCUS=1 ZELLIJ_NAV_PROTECTED_COMMAND_PATTERN='a^' bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "picker navigation completed"
  run jq -e '.kind == "pane" and .session == "current" and .pane_id == 9' "$ZELLIJ_NAV_STATE_DIR/previous-target.json"
  [ "$status" -eq 0 ]
}

@test "protected codex context blocks picker navigation by default" {
  run env ZELLIJ_PANE_ID=1 ZELLIJ_STUB_PROTECTED_SELF=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "protected context blocked reason=no-client-scoped-zellij-mutation"
  wait_for_log "navigation transaction aborted reason=focus-failed"
  wait_for_log "picker navigation failed"
  run grep -q "picker navigation completed" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
  run grep -q "zellij action start-or-reload-plugin" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "zellij action switch-session target" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "unfocused cdx pane does not make helper context protected" {
  run env ZELLIJ_PANE_ID=2 ZELLIJ_STUB_PROTECTED_TERMINAL_COMMAND=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "picker navigation completed"
  run grep -q "protected context blocked reason=no-client-scoped-zellij-mutation" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
  run grep -q "zellij action switch-session target" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "protected codex context can explicitly try plugin strategy but requires confirmation" {
  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_STUB_PROTECTED_SELF=1 \
    ZELLIJ_NAV_PROTECTED_STRATEGY=plugin \
    ZELLIJ_NAV_PLUGIN_SWITCH_COMMAND="$PLUGIN_SWITCH" \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "protected context detected route=plugin"
  wait_for_log "plugin navigation failed reason=unconfirmed"
  wait_for_log "picker navigation failed"
  run grep -q "zellij action start-or-reload-plugin" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "file:.*zellij-nav-switcher.wasm" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q -- "--configuration session=target,kind=session" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij action switch-session target" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "protected plugin navigation failure preserves previous target history" {
  write_previous_target

  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_STUB_PROTECTED_SELF=1 \
    ZELLIJ_NAV_PROTECTED_STRATEGY=plugin \
    ZELLIJ_NAV_PLUGIN_SWITCH_COMMAND="$WORK/missing-plugin-switch" \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "plugin navigation failed reason=missing-command"
  wait_for_log "navigation transaction aborted reason=focus-failed"
  run jq -e '.kind == "session" and .session == "target"' "$ZELLIJ_NAV_STATE_DIR/previous-target.json"
  [ "$status" -eq 0 ]
  run grep -q "picker navigation completed" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
}

@test "plugin switch converts tab id to tab position before plugin configuration" {
  run bash "$PLUGIN_SWITCH" target tab 9 ""
  [ "$status" -eq 0 ]

  run grep -q -- "--configuration session=target,kind=tab,tab_id=1,pane_id=" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "protected codex context can opt in to sidecar fallback" {
  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_STUB_PROTECTED_SELF=1 \
    ZELLIJ_NAV_PROTECTED_STRATEGY=sidecar \
    ZELLIJ_NAV_SIDECAR_COMMAND="$SIDECAR" \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "protected context detected route=sidecar"
  wait_for_log "sidecar navigation accepted session=target"
  wait_for_log "picker navigation completed"
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij attach target" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q -- "--new-session-with-layout" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "zellij action switch-session target" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "protected sidecar falls back to new wezterm process when cli spawn fails" {
  run env \
    ZELLIJ_PANE_ID=1 \
    ZELLIJ_STUB_PROTECTED_SELF=1 \
    ZELLIJ_STUB_WEZTERM_CLI_FAIL=1 \
    ZELLIJ_NAV_PROTECTED_STRATEGY=sidecar \
    ZELLIJ_NAV_SIDECAR_COMMAND="$SIDECAR" \
    bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "protected context detected route=sidecar"
  wait_for_log "sidecar navigation accepted session=target"
  wait_for_log "picker navigation completed"
  run grep -q "wezterm cli spawn" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "wezterm start --always-new-process" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "route=start-process" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -eq 0 ]
}

@test "sidecar pane target prepares exact pane before direct attach" {
  run bash "$SIDECAR" target pane 0 7
  [ "$status" -eq 0 ]

  run grep -q "zellij --session target action go-to-tab-by-id 0" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij --session target action focus-pane-id terminal_7" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij attach target" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q -- "--new-session-with-layout" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "sidecar tab target prepares stable tab before direct attach" {
  run bash "$SIDECAR" target tab 0 ""
  [ "$status" -eq 0 ]

  run grep -q "zellij --session target action go-to-tab-by-id 0" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "zellij attach target" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
}

@test "helper exit closes only verified floating helper pane" {
  run env ZELLIJ_PANE_ID=42 ZELLIJ_NAV_HELPER=1 ZELLIJ_STUB_HELPER_SELF=1 bash "$TOGGLE"
  [ "$status" -eq 0 ]

  wait_for_log "closing helper pane session=current pane=terminal_42"
  wait_for_log "closed helper pane session=current pane=terminal_42"
  run grep -q "zellij --session current action close-pane --pane-id terminal_42" "$ZELLIJ_STUB_LOG"
  [ "$status" -eq 0 ]
  run grep -q "close-pane --pane-id terminal_7" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "picker preview subprocess never closes the helper pane" {
  env \
    ZELLIJ_PANE_ID=42 \
    ZELLIJ_NAV_HELPER=1 \
    ZELLIJ_STUB_HELPER_SELF=1 \
    ZELLIJ_PICKER_PREVIEW_LIVE_DELAY=30 \
    bash "$PICKER" --render-preview session target - - - target >/dev/null &
  preview_pid=$!
  sleep 0.1
  kill "$preview_pid" 2>/dev/null || true
  wait "$preview_pid" 2>/dev/null || true

  run grep -q "close-pane" "$ZELLIJ_STUB_LOG"
  [ "$status" -ne 0 ]
  run grep -q "closing helper pane" "$ZELLIJ_NAV_STATE_DIR/zellij-navigation.log"
  [ "$status" -ne 0 ]
}

@test "dead-owner navigation lease lock is recovered before navigation" {
  mkdir "$ZELLIJ_NAV_STATE_DIR/.navigation.lock"
  date '+%s' >"$ZELLIJ_NAV_STATE_DIR/.navigation.lock/created_at"
  printf '999999\n' >"$ZELLIJ_NAV_STATE_DIR/.navigation.lock/owner_pid"

  run env ZELLIJ_PANE_ID=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "navigation lease lock reclaimed reason=dead-owner owner_pid=999999"
  wait_for_log "picker navigation completed"
}

@test "expired navigation lease lock is recovered before navigation" {
  mkdir "$ZELLIJ_NAV_STATE_DIR/.navigation.lock"
  printf '%s\n' "$(($(date '+%s') - 20))" >"$ZELLIJ_NAV_STATE_DIR/.navigation.lock/created_at"
  printf '%s\n' "$$" >"$ZELLIJ_NAV_STATE_DIR/.navigation.lock/owner_pid"

  run env ZELLIJ_PANE_ID=1 ZELLIJ_NAV_LOCK_LEASE_TTL_SECONDS=1 bash "$PICKER" --sessions
  [ "$status" -eq 0 ]

  wait_for_log "navigation lease lock reclaimed reason=ttl-expired"
  wait_for_log "picker navigation completed"
}
