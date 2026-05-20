#!/usr/bin/env bash
# PostToolUse Sensor: Auto-lint after file edits
# Runs language-appropriate linter/formatter and feeds results back to Claude.
#
# Exit codes:
#   0 = always (non-blocking sensor)
#
# Lint results go to stdout — Claude reads them as feedback.
# Uses a cache to avoid repeating identical lint feedback.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null)

case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)
[[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"
BASENAME=$(basename "$FILE_PATH")
LINT_OUTPUT=""
LINT_CMD=""

case "$EXT" in
  nix)
    if command -v alejandra &>/dev/null; then
      LINT_CMD="alejandra"
      LINT_OUTPUT=$(alejandra --check "$FILE_PATH" 2>&1) || true
    elif command -v nixfmt &>/dev/null; then
      LINT_CMD="nixfmt"
      LINT_OUTPUT=$(nixfmt --check "$FILE_PATH" 2>&1) || true
    fi
    ;;
  sh|bash)
    if command -v shellcheck &>/dev/null; then
      LINT_CMD="shellcheck"
      LINT_OUTPUT=$(shellcheck -f gcc "$FILE_PATH" 2>&1 | head -20) || true
    fi
    ;;
  ts|tsx|js|jsx)
    if command -v prettier &>/dev/null; then
      LINT_CMD="prettier"
      LINT_OUTPUT=$(prettier --check "$FILE_PATH" 2>&1) || true
    fi
    ;;
  go)
    if command -v gofmt &>/dev/null; then
      LINT_CMD="gofmt"
      # gofmt -l lists files that need formatting
      LINT_OUTPUT=$(gofmt -l "$FILE_PATH" 2>&1) || true
    fi
    ;;
  py)
    if command -v ruff &>/dev/null; then
      LINT_CMD="ruff"
      LINT_OUTPUT=$(ruff check "$FILE_PATH" 2>&1 | head -20) || true
    fi
    ;;
  lua)
    if command -v stylua &>/dev/null; then
      LINT_CMD="stylua"
      LINT_OUTPUT=$(stylua --check "$FILE_PATH" 2>&1) || true
    fi
    ;;
  md)
    # Skip markdown — no actionable lint for agent
    exit 0
    ;;
esac

# No linter available or no output → silent exit
[[ -z "$LINT_CMD" || -z "$LINT_OUTPUT" ]] && exit 0

# Cache: skip if lint output is identical to previous run
CACHE_DIR="${TMPDIR:-/tmp}/claude-autolint"
mkdir -p "$CACHE_DIR"
CACHE_KEY=$(echo "$FILE_PATH" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "$BASENAME")
CACHE_FILE="$CACHE_DIR/$CACHE_KEY"
CURRENT_HASH=$(echo "$LINT_OUTPUT" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "none")

if [[ -f "$CACHE_FILE" ]] && [[ "$(cat "$CACHE_FILE")" == "$CURRENT_HASH" ]]; then
  # Same lint output as before — don't repeat feedback (prevents infinite loop)
  exit 0
fi
echo "$CURRENT_HASH" > "$CACHE_FILE"

# Output feedback for Claude
echo "[AUTO-LINT] $LINT_CMD found issues in $BASENAME:"
echo "$LINT_OUTPUT" | head -10

exit 0
