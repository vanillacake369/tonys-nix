#!/usr/bin/env bats
# strategy-lint generated script: reversibility-tiered section enforcement.
# Tests the generated script's reversibility branch by invoking it with a
# temp reversibility marker. Paths are env-overridable to match test isolation.

setup() {
  WORK=$(mktemp -d)
  export TMPDIR="$WORK/tmp"
  mkdir -p "$TMPDIR"
  export COMPLEXITY_DIR="$WORK/complexity"
  mkdir -p "$COMPLEXITY_DIR"
  export STRATEGY_DIR="$WORK/strategy"
  mkdir -p "$STRATEGY_DIR"

  # Build a minimal strategy-lint script that mirrors the mixin output.
  # Env-overridable: COMPLEXITY_DIR, STRATEGY_DIR (injected above).
  # This script is a test double for the nix-generated strategy-lint-claude.sh.
  SCRIPT="$WORK/strategy-lint-test.sh"
  cat > "$SCRIPT" <<'SCRIPT_EOF'
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)

# Only gate mutation tools
case "$TOOL_NAME" in
  Write|Edit|NotebookEdit) ;;
  *) exit 0 ;;
esac

STRATEGY_DIR="${STRATEGY_DIR:-/tmp/claude-strategy}"
COMPLEXITY_DIR="${COMPLEXITY_DIR:-/tmp/claude-complexity}"
STRATEGY_FILE="$STRATEGY_DIR/$SESSION_ID.md"

# No strategy file yet — allow (first-time pass)
[[ ! -f "$STRATEGY_FILE" ]] && exit 0

# Reversibility gate: skip enforcement for reversible work
REVERSIBILITY_FILE="$COMPLEXITY_DIR/${SESSION_ID}.reversibility"
if [[ ! -f "$REVERSIBILITY_FILE" ]] || [[ "$(cat "$REVERSIBILITY_FILE")" != "irreversible" ]]; then
  exit 0
fi

# Required sections check (irreversible only)
MISSING=()
REQUIRED_SECTIONS=("pre-mortem" "tradeoffs" "peer-review" "grilled-decisions")
for s in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qi "$s" "$STRATEGY_FILE" 2>/dev/null; then
    MISSING+=("$s")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "[STRATEGY-LINT] Missing required sections: ${MISSING[*]}"
  echo "Add these sections to $STRATEGY_FILE before proceeding."
  exit 2
fi

# Peer review gate
REVIEW_FILE="$STRATEGY_DIR/${SESSION_ID}-review.md"
if [[ ! -f "$REVIEW_FILE" ]]; then
  echo "[STRATEGY-LINT] Peer review not found."
  echo "Expected: $REVIEW_FILE"
  exit 2
fi

exit 0
SCRIPT_EOF
  chmod +x "$SCRIPT"
  HOOK="$SCRIPT"
}

teardown() { rm -rf "$WORK"; }

mkinput() {
  local tool="${1:-Edit}"
  local session="${2:-s1}"
  printf '{"tool_name":"%s","session_id":"%s"}' "$tool" "$session"
}

make_strategy() {
  # $1=session, $2=content
  echo "$2" > "$STRATEGY_DIR/${1}.md"
}

make_review() {
  # $1=session
  echo "peer review content" > "$STRATEGY_DIR/${1}-review.md"
}

run_hook() {
  printf '%s' "$1" > "$WORK/input.json"
  COMPLEXITY_DIR="$COMPLEXITY_DIR" STRATEGY_DIR="$STRATEGY_DIR" run bash "$HOOK" <"$WORK/input.json"
}

# ─── Reversibility: reversible → always exit 0, no section check ─────────────

@test "reversible marker → exit 0 even with incomplete strategy" {
  local session="s-rev"
  echo "reversible" > "$COMPLEXITY_DIR/${session}.reversibility"
  make_strategy "$session" "# My plan — no sections at all"
  run_hook "$(mkinput Edit "$session")"
  [ "$status" -eq 0 ]
}

@test "missing reversibility file → exit 0 (defaults to reversible)" {
  local session="s-missing"
  make_strategy "$session" "# incomplete plan, no sections"
  run_hook "$(mkinput Edit "$session")"
  [ "$status" -eq 0 ]
}

# ─── Reversibility: irreversible + missing sections → exit 2 ─────────────────

@test "irreversible + no sections → exit 2" {
  local session="s-irr"
  echo "irreversible" > "$COMPLEXITY_DIR/${session}.reversibility"
  make_strategy "$session" "# My plan with no required sections"
  run_hook "$(mkinput Edit "$session")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"[STRATEGY-LINT]"* ]]
  [[ "$output" == *"pre-mortem"* ]] || [[ "$output" == *"tradeoffs"* ]]
}

@test "irreversible + all sections but no peer-review → exit 2" {
  local session="s-noreview"
  echo "irreversible" > "$COMPLEXITY_DIR/${session}.reversibility"
  make_strategy "$session" "$(cat <<'EOF'
# Strategy
## pre-mortem
stuff
## tradeoffs
stuff
## peer-review
stuff
## grilled-decisions
stuff
EOF
)"
  # No review file → should fail
  run_hook "$(mkinput Edit "$session")"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Peer review"* ]]
}

@test "irreversible + all sections + peer-review → exit 0" {
  local session="s-full"
  echo "irreversible" > "$COMPLEXITY_DIR/${session}.reversibility"
  make_strategy "$session" "$(cat <<'EOF'
# Strategy
## pre-mortem
stuff
## tradeoffs
stuff
## peer-review
stuff
## grilled-decisions
stuff
EOF
)"
  make_review "$session"
  run_hook "$(mkinput Edit "$session")"
  [ "$status" -eq 0 ]
}

# ─── Non-mutation tools always pass ──────────────────────────────────────────

@test "Read tool → exit 0 regardless of reversibility" {
  local session="s-read"
  echo "irreversible" > "$COMPLEXITY_DIR/${session}.reversibility"
  make_strategy "$session" "# no sections"
  run_hook "$(mkinput Read "$session")"
  [ "$status" -eq 0 ]
}

# ─── No strategy file → first-time pass ──────────────────────────────────────

@test "no strategy file → exit 0 (first-time pass)" {
  local session="s-nostrat"
  echo "irreversible" > "$COMPLEXITY_DIR/${session}.reversibility"
  # Deliberately do NOT create strategy file
  run_hook "$(mkinput Edit "$session")"
  [ "$status" -eq 0 ]
}
