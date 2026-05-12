#!/usr/bin/env bash
# Called by terminal-notifier -execute on notification click
# Usage: agent-notify-open.sh [zellij_session_name] [transcript_path]
# Focuses WezTerm, switches zellij sessions, and opens transcript if provided.
#
# Note: terminal-notifier -execute runs with minimal PATH (/usr/bin:/bin:/usr/sbin:/sbin).
# Nix binaries are not available, so we prepend ~/.nix-profile/bin.
set -uo pipefail

export PATH="$HOME/.nix-profile/bin:$PATH"

TARGET="" TRANSCRIPT=""

# Parse args: first non-file arg is zellij session, file arg is transcript
for arg in "$@"; do
  if [[ -f "$arg" ]]; then
    TRANSCRIPT="$arg"
  elif [[ -z "$TARGET" ]]; then
    TARGET="$arg"
  fi
done

# Focus WezTerm and wait for it to become foreground
open -a WezTerm 2>/dev/null || true
sleep 0.3

# Switch zellij sessions if target is specified
if [[ -n "$TARGET" ]] && command -v zellij &>/dev/null; then
  zellij list-sessions 2>/dev/null \
    | grep -v EXITED \
    | sed 's/\x1b\[[0-9;]*m//g' \
    | awk '{print $1}' \
    | while read -r s; do
        if [[ "$s" != "$TARGET" && -n "$s" ]]; then
          zellij -s "$s" action switch-session "$TARGET" 2>/dev/null || true
        fi
      done
fi

# Open transcript in default editor if available
if [[ -n "$TRANSCRIPT" ]]; then
  open "$TRANSCRIPT" 2>/dev/null || true
fi
