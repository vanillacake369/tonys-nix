#!/usr/bin/env bash
# Called by terminal-notifier -execute on notification click
# Usage: agent-notify-open.sh [zellij_session_name] [transcript_path]
# Focuses terminal, switches zellij sessions via strategy router, opens transcript.
#
# Strategy Router: detects terminal type (wezterm|ghostty|*) and dispatches
# to the appropriate session-switch implementation.
#
# Note: terminal-notifier -execute runs with minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin).
# Nix binaries are not available, so we prepend ~/.nix-profile/bin.
#
# Env: AGENT_NOTIFY_TERMINAL  - terminal app name (WezTerm|Ghostty|...)
#      AGENT_NOTIFY_PROVIDER  - agent provider (claude|gemini|codex)
#      _TEST_DRY_RUN          - if set, don't execute side effects
#      _TEST_WEZTERM_TITLE    - inject WezTerm pane title for testing
set -uo pipefail

export PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

# ===========================================================================
# Terminal Detection (SSoT)
# Normalizes AGENT_NOTIFY_TERMINAL to lowercase identifier.
# ===========================================================================
_detect_terminal() {
  local raw="${AGENT_NOTIFY_TERMINAL:-}"
  # Normalize: lowercase, strip whitespace
  local term
  term=$(echo "$raw" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
  # Map known names
  case "$term" in
    wezterm|wezterm-gui) echo "wezterm" ;;
    ghostty)            echo "ghostty" ;;
    "")                 echo "unknown" ;;
    *)                  echo "$term" ;;
  esac
}

# ===========================================================================
# Detect current zellij session from WezTerm pane title
# Zellij sets title as "session_name | ..." or "session_name - ..."
# ===========================================================================
_detect_current_session() {
  local title="${_TEST_WEZTERM_TITLE-__unset__}"
  if [[ "$title" == "__unset__" ]] && command -v wezterm &>/dev/null; then
    title=$(wezterm cli list --format json 2>/dev/null \
      | python3 -c "
import sys,json
for p in json.load(sys.stdin):
    print(p.get('title','')); break
" 2>/dev/null || true)
  fi
  # Extract session name: everything before " | " or " - "
  local session=""
  if [[ -n "$title" ]]; then
    session=$(echo "$title" | sed -E 's/ [|] .*//;s/ - .*//' | tr -d '[:space:]' | head -1)
  fi
  echo "$session"
}

# ===========================================================================
# Focus terminal app (platform-specific)
# ===========================================================================
_focus_terminal() {
  local app="${AGENT_NOTIFY_TERMINAL:-WezTerm}"
  if [[ -z "${_TEST_DRY_RUN:-}" ]]; then
    open -a "$app" 2>/dev/null || true
  fi
}

# ===========================================================================
# Strategy: WezTerm
# Uses wezterm cli send-text to type zellij switch command into active pane.
# Works when the current pane has an idle shell (typical at notification time).
# ===========================================================================
_switch_wezterm() {
  local target="$1"
  local current
  current=$(_detect_current_session)

  if [[ "$current" == "$target" ]]; then
    echo "action=skip reason=already-on-target"
    return 0
  fi

  local pane_id="${_TEST_WEZTERM_PANE:-}"
  if [[ -z "$pane_id" ]] && command -v wezterm &>/dev/null; then
    pane_id=$(wezterm cli list --format json 2>/dev/null \
      | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['pane_id'])" 2>/dev/null || true)
  fi

  if [[ -n "$pane_id" ]]; then
    echo "action=send-text pane=$pane_id target=$target"
    if [[ -z "${_TEST_DRY_RUN:-}" ]]; then
      wezterm cli send-text --pane-id "$pane_id" --no-paste \
        -- "zellij action switch-session ${target}"$'\r' 2>/dev/null || true
    fi
  else
    echo "action=focus-only reason=no-pane"
  fi
}

# ===========================================================================
# Strategy: Ghostty
# Placeholder for future libghostty / Ghostty CLI integration.
# ===========================================================================
_switch_ghostty() {
  local target="$1"
  # TODO: implement Ghostty-specific session switch when API is available
  echo "action=focus-only reason=ghostty-not-yet-implemented target=$target"
}

# ===========================================================================
# Strategy: Fallback (unknown terminal)
# Just focus the terminal; user switches manually.
# ===========================================================================
_switch_fallback() {
  local target="$1"
  echo "action=focus-only reason=unknown-terminal target=$target"
}

# ===========================================================================
# Strategy Router: dispatch to terminal-specific implementation
# ===========================================================================
_switch_session() {
  local target="$1"
  local terminal
  terminal=$(_detect_terminal)

  if [[ -z "$target" ]]; then
    echo "strategy=none action=focus-only reason=no-target"
    return 0
  fi

  case "$terminal" in
    wezterm)
      echo "strategy=wezterm"
      _switch_wezterm "$target"
      ;;
    ghostty)
      echo "strategy=ghostty"
      _switch_ghostty "$target"
      ;;
    *)
      echo "strategy=fallback"
      _switch_fallback "$target"
      ;;
  esac
}

# ===========================================================================
# Transcript opening (provider-gated)
# ===========================================================================
_should_open_transcript() {
  local provider="${AGENT_NOTIFY_PROVIDER:-}"
  local path="$1"
  [[ -n "$path" && "$provider" != "gemini" && "$provider" != "codex" ]]
}

_open_transcript() {
  local path="$1"
  if _should_open_transcript "$path"; then
    if [[ -z "${_TEST_DRY_RUN:-}" ]]; then
      open "$path" 2>/dev/null || true
    fi
    echo "open=true"
  else
    echo "open=false"
  fi
}

# ===========================================================================
# Test modes (invoked by test harness)
# ===========================================================================
case "${1:-}" in
  --detect-terminal-test)
    echo "terminal=$(_detect_terminal)"; exit 0 ;;
  --detect-session-test)
    echo "session=$(_detect_current_session)"; exit 0 ;;
  --switch-test)
    _switch_session "${2:-}"; exit 0 ;;
  --transcript-test)
    _open_transcript "${2:-}"; exit 0 ;;
esac

# ===========================================================================
# Main
# ===========================================================================
PROVIDER="${AGENT_NOTIFY_PROVIDER:-}"
TARGET="" TRANSCRIPT=""

# Parse args: first non-file arg is zellij session, file arg is transcript
for arg in "$@"; do
  if [[ -f "$arg" ]]; then
    TRANSCRIPT="$arg"
  elif [[ -z "$TARGET" ]]; then
    TARGET="$arg"
  fi
done

_focus_terminal
_switch_session "$TARGET" >/dev/null
sleep 0.1
if _should_open_transcript "$TRANSCRIPT"; then
  open "$TRANSCRIPT" 2>/dev/null || true
fi
