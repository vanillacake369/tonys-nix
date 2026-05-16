#!/usr/bin/env bash
# Claude Code status line hook
# Outputs 2 lines:
#   Line 1: [Model] 📁 dirname | 🌿 branch +staged ~modified | 🤖 agent_name
#   Line 2: ████░░░░░░ 42% | $0.45 | ⏱ 3m 12s | 5h:23%
#
# Input: JSON via stdin from Claude Code
# This hook never exits non-zero — it must not block the agent.

set -uo pipefail

# ANSI colors
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ===========================================================================
# Parse input JSON
# ===========================================================================
INPUT=$(cat 2>/dev/null || true)

_jq() {
  echo "$INPUT" | jq -r "${1}" 2>/dev/null || true
}

MODEL=$(_jq '.model.display_name // "Claude"')
CURRENT_DIR=$(_jq '.workspace.current_dir // ""')
USED_PCT=$(_jq '.context_window.used_percentage // 0')
TOTAL_COST=$(_jq '.cost.total_cost_usd // 0')
DURATION_MS=$(_jq '.cost.total_duration_ms // 0')
SESSION_ID=$(_jq '.session_id // "default"')
AGENT_NAME=$(_jq '.agent.name // ""')
FIVE_HOUR_PCT=$(_jq '.rate_limits.five_hour.used_percentage // ""')

# ===========================================================================
# Git info with 5-second cache (keyed by session_id)
# ===========================================================================
CACHE_DIR="${TMPDIR:-/tmp}/claude-statusline"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/${SESSION_ID//[^a-zA-Z0-9_-]/_}.cache"
CACHE_TTL=5

_get_cache_mtime() {
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f %m "$1" 2>/dev/null || echo 0
  else
    stat -c %Y "$1" 2>/dev/null || echo 0
  fi
}

_get_git_info() {
  local dir="${1:-$(pwd)}"
  if ! git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
    echo ""
    return
  fi

  local branch staged modified
  branch=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$dir" rev-parse --short HEAD 2>/dev/null \
    || echo "HEAD")

  staged=$(git -C "$dir" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  modified=$(git -C "$dir" diff --name-only 2>/dev/null | wc -l | tr -d ' ')

  echo "${branch}|${staged}|${modified}"
}

NOW=$(date +%s)
CACHE_MTIME=$(_get_cache_mtime "$CACHE_FILE")

if [[ $((NOW - CACHE_MTIME)) -gt $CACHE_TTL ]]; then
  GIT_DATA=$(_get_git_info "${CURRENT_DIR:-$(pwd)}")
  echo "$GIT_DATA" > "$CACHE_FILE"
else
  GIT_DATA=$(cat "$CACHE_FILE" 2>/dev/null || echo "")
fi

# ===========================================================================
# Build Line 1
# ===========================================================================
DIRNAME=""
if [[ -n "$CURRENT_DIR" ]]; then
  DIRNAME=$(basename "$CURRENT_DIR")
fi

GIT_PART=""
if [[ -n "$GIT_DATA" ]]; then
  IFS='|' read -r BRANCH STAGED MODIFIED <<< "$GIT_DATA"
  STAGED_STR=""
  MODIFIED_STR=""
  if [[ "$STAGED" -gt 0 ]]; then
    STAGED_STR="${GREEN}+${STAGED}${RESET}"
  fi
  if [[ "$MODIFIED" -gt 0 ]]; then
    MODIFIED_STR="${YELLOW}~${MODIFIED}${RESET}"
  fi

  if [[ -n "$STAGED_STR" && -n "$MODIFIED_STR" ]]; then
    GIT_PART=" | 🌿 ${BRANCH} ${STAGED_STR} ${MODIFIED_STR}"
  elif [[ -n "$STAGED_STR" ]]; then
    GIT_PART=" | 🌿 ${BRANCH} ${STAGED_STR}"
  elif [[ -n "$MODIFIED_STR" ]]; then
    GIT_PART=" | 🌿 ${BRANCH} ${MODIFIED_STR}"
  else
    GIT_PART=" | 🌿 ${BRANCH}"
  fi
fi

AGENT_PART=""
if [[ -n "$AGENT_NAME" ]]; then
  AGENT_PART=" | 🤖 ${AGENT_NAME}"
fi

LINE1="[${MODEL}] 📁 ${DIRNAME}${GIT_PART}${AGENT_PART}"

# ===========================================================================
# Build Line 2
# ===========================================================================

# Context progress bar (10 chars)
USED_INT=${USED_PCT%.*}
USED_INT=${USED_INT:-0}
FILLED=$(( (USED_INT * 10 + 50) / 100 ))
[[ $FILLED -gt 10 ]] && FILLED=10
[[ $FILLED -lt 0 ]] && FILLED=0
EMPTY=$(( 10 - FILLED ))

if [[ $USED_INT -ge 90 ]]; then
  BAR_COLOR="$RED"
elif [[ $USED_INT -ge 70 ]]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$GREEN"
fi

BAR_FILLED=$(printf '%0.s█' $(seq 1 $FILLED) 2>/dev/null || printf '█%.0s' $(seq 1 $FILLED))
BAR_EMPTY=$(printf '%0.s░' $(seq 1 $EMPTY) 2>/dev/null || printf '░%.0s' $(seq 1 $EMPTY))
PROGRESS_BAR="${BAR_COLOR}${BAR_FILLED}${BAR_EMPTY}${RESET} ${USED_INT}%"

# Cost
COST_STR=$(printf '\$%.2f' "$TOTAL_COST" 2>/dev/null || echo "\$0.00")

# Elapsed time
DURATION_S=$(( DURATION_MS / 1000 ))
ELAPSED_MIN=$(( DURATION_S / 60 ))
ELAPSED_SEC=$(( DURATION_S % 60 ))
ELAPSED_STR="⏱ ${ELAPSED_MIN}m ${ELAPSED_SEC}s"

# 5-hour rate limit
RATE_PART=""
if [[ -n "$FIVE_HOUR_PCT" && "$FIVE_HOUR_PCT" != "null" ]]; then
  FIVE_HOUR_INT=${FIVE_HOUR_PCT%.*}
  RATE_PART=" | 5h:${FIVE_HOUR_INT}%"
fi

LINE2="${PROGRESS_BAR} | ${COST_STR} | ${ELAPSED_STR}${RATE_PART}"

# ===========================================================================
# Output
# ===========================================================================
printf '%b\n%b\n' "$LINE1" "$LINE2"
