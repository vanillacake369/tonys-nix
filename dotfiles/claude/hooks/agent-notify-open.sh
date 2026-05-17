#!/usr/bin/env bash
# Called by terminal-notifier -execute on notification click
# Usage: agent-notify-open.sh [zellij_session_name] [transcript_path]
# Focuses WezTerm, switches zellij sessions, and opens transcript if provided.
#
# Note: terminal-notifier -execute runs with minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin).
# Nix binaries are not available, so we prepend ~/.nix-profile/bin.
set -uo pipefail

export PATH="$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"

TERMINAL_APP="${AGENT_NOTIFY_TERMINAL:-WezTerm}"
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

# Focus terminal app
open -a "$TERMINAL_APP" 2>/dev/null || true

# Focus target zellij session if specified
if [[ -n "$TARGET" ]]; then
  focused=false

  # 1. Try to find and focus a WezTerm pane running the target session
  if [[ "$TERMINAL_APP" == "WezTerm" ]] && command -v wezterm &>/dev/null && command -v jq &>/dev/null; then
    # Search for TARGET in window_title or title. 
    # Zellij usually sets title to "session_name | ..." or "... (session_name)"
    PANE_ID=$(wezterm cli list --format json | jq -r ".[] | select(.window_title | contains(\"$TARGET\")) | .pane_id" | head -n 1)
    if [[ -n "$PANE_ID" && "$PANE_ID" != "null" ]]; then
      wezterm cli activate-pane --pane-id "$PANE_ID" 2>/dev/null || true
      focused=true
    fi
  fi

  # 2. Fallback: if not focused via terminal-specific CLI, 
  # we could switch the session of the current client.
  # But we must avoid switching ALL sessions (the "A switches to B" bug).
  # We only switch if we can identify a single "current" session to affect.
  if [[ "$focused" == "false" ]]; then
    # If we are in Zellij already, we might want to switch the current session.
    # But from a notification click, we don't have a 'current' session context.
    # To be safe and avoid the reported bug, we do NOT switch all sessions.
    # Instead, we just let 'open -a' focus the terminal and the user can decide.
    true
  fi
fi

# Give it a moment to focus
sleep 0.1

# Open transcript only for Claude (other providers' JSON files cause focus issues)
if [[ -n "$TRANSCRIPT" && "$PROVIDER" != "gemini" && "$PROVIDER" != "codex" ]]; then
  open "$TRANSCRIPT" 2>/dev/null || true
fi
