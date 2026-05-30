#!/usr/bin/env bash
# A/B experiment harness for semantic-oracle.sh (synthetic replay).
#
# PURPOSE: measures oracle-side differential only — how the semantic-oracle hook
# behaves under arm=on vs arm=off for a fixed set of edit scenarios.
#
# IMPORTANT: real token/turn cost estimation requires accumulated real session
# data via tonys-agent-telemetry (github.com/vanillacake369/tonys-agent-telemetry).
# This harness measures *oracle-side differential only*: pass/fail/fallback counts,
# mean latency_ms, and the "would-be-rework-catches" proxy (fail-new under arm=on).
#
# Fixtures used:
#   go  — one breaking edit (go build fails), one clean edit (go build passes)
#   lua — no diagnose entry → exercises fallback-no-diagnose path
#
# Env overrides consumed from semantic-oracle.sh:
#   LANG_TOOLS_JSON      tool table JSON
#   EXPERIMENT_ARM_FILE  on|off arm selector
#   COMPLEXITY_DIR       per-session complexity files
#   TELEMETRY_FILE       output JSONL
#
# Usage: bash tests/experiments/ab-oracle.sh
# Clean-up: all temp fixtures are removed on exit.

set -uo pipefail

ORACLE="$(cd "$(dirname "$0")/../.." && pwd)/dotfiles/claude/hooks/semantic-oracle.sh"
if [[ ! -f "$ORACLE" ]]; then
  echo "[ab-oracle] ERROR: oracle not found at $ORACLE" >&2
  exit 1
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Build two tiny real Go module fixtures (so go build ./... actually runs)
# clean_mod: valid Go → go build passes
# broken_mod: syntax error → go build fails
# ---------------------------------------------------------------------------
GO_CLEAN_DIR="$WORK/fixtures/go_clean"
mkdir -p "$GO_CLEAN_DIR"
cat > "$GO_CLEAN_DIR/go.mod" <<'EOF'
module example.com/ab-test-clean

go 1.21
EOF
cat > "$GO_CLEAN_DIR/main.go" <<'EOF'
package main

import "fmt"

func main() {
  fmt.Println("hello")
}
EOF

GO_BROKEN_DIR="$WORK/fixtures/go_broken"
mkdir -p "$GO_BROKEN_DIR"
cat > "$GO_BROKEN_DIR/go.mod" <<'EOF'
module example.com/ab-test-broken

go 1.21
EOF
# syntax error: missing closing paren → go build ./... fails
cat > "$GO_BROKEN_DIR/broken.go" <<'EOF'
package main

func brokenFunc( {
}
EOF

# Lua fixture — no diagnose entry → fallback-no-diagnose path
LUA_FILE="$WORK/fixtures/script.lua"
mkdir -p "$(dirname "$LUA_FILE")"
echo "local x = 1" > "$LUA_FILE"

# ---------------------------------------------------------------------------
# SSoT tool table (go has diagnose, lua does not)
# ---------------------------------------------------------------------------
TOOLS_JSON="$WORK/lang-tools.json"
cat > "$TOOLS_JSON" <<'EOF'
{
  "go": {
    "format": "gofmt -l",
    "diagnose": "go build ./..."
  },
  "lua": {
    "format": "stylua --check"
  }
}
EOF

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
COMPLEXITY_DIR="$WORK/complexity"
mkdir -p "$COMPLEXITY_DIR"
for sid in s1 s2 s3 s4 s5 s6; do echo "L" > "$COMPLEXITY_DIR/$sid"; done

ARM_FILE="$WORK/arm"
TELEMETRY="$WORK/telemetry.jsonl"

ORACLE_TMP="$WORK/tmp"
mkdir -p "$ORACLE_TMP"

run_scenario() {
  # $1=arm $2=file_path $3=session_id $4=run_dir (optional, cwd for diagnose cmd)
  local arm="$1" fpath="$2" sid="${3:-s1}" run_dir="${4:-}"
  echo "$arm" > "$ARM_FILE"
  local input
  input=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"},"session_id":"%s"}' "$fpath" "$sid")
  # Invoke the oracle from the correct run_dir so `go build ./...` resolves correctly.
  # Capture exit code without failing the harness.
  (
    [[ -n "$run_dir" ]] && cd "$run_dir"
    TMPDIR="$ORACLE_TMP" \
    LANG_TOOLS_JSON="$TOOLS_JSON" \
    EXPERIMENT_ARM_FILE="$ARM_FILE" \
    COMPLEXITY_DIR="$COMPLEXITY_DIR" \
    TELEMETRY_FILE="$TELEMETRY" \
      bash "$ORACLE" <<< "$input" >/dev/null 2>/dev/null
  ) || true
}

# ---------------------------------------------------------------------------
# Replay scenarios
# ---------------------------------------------------------------------------
# Scenario 1: clean Go module — arm=on → pass; arm=off → skip-arm-off
GO_CLEAN_FILE="$GO_CLEAN_DIR/main.go"
# Scenario 2: broken Go module — arm=on → fail-new; arm=off → skip-arm-off
GO_BROKEN_FILE="$GO_BROKEN_DIR/broken.go"
# Scenario 3: lua file — arm=on → fallback-no-diagnose; arm=off → skip-arm-off

echo "[ab-oracle] Replaying scenarios under arm=on ..."
run_scenario "on"  "$GO_CLEAN_FILE"   "s1" "$GO_CLEAN_DIR"
run_scenario "on"  "$GO_BROKEN_FILE"  "s2" "$GO_BROKEN_DIR"
run_scenario "on"  "$LUA_FILE"        "s3" ""

echo "[ab-oracle] Replaying scenarios under arm=off ..."
run_scenario "off" "$GO_CLEAN_FILE"   "s4" "$GO_CLEAN_DIR"
run_scenario "off" "$GO_BROKEN_FILE"  "s5" "$GO_BROKEN_DIR"
run_scenario "off" "$LUA_FILE"        "s6" ""

# ---------------------------------------------------------------------------
# Aggregate telemetry
# ---------------------------------------------------------------------------
echo ""
echo "=== A/B Oracle Experiment Results ============================================="
printf "%-8s  %-20s  %5s  %5s  %5s  %5s  %5s  %5s  %5s  %12s  %s\n" \
  "arm" "result" "pass" "fail-n" "adv-n" "fail-u" "fb-nd" "fb-tm" "skip" "mean-lat-ms" "would-be-rework-catches"

for arm in on off; do
  count_pass=0; count_fail_new=0; count_adv_new=0; count_fail_unch=0
  count_fb_nd=0; count_fb_tm=0; count_skip=0
  total_lat=0; n_lat=0

  while IFS= read -r line; do
    r=$(echo "$line" | jq -r '.result' 2>/dev/null) || continue
    lat=$(echo "$line" | jq -r '.latency_ms // 0' 2>/dev/null) || lat=0
    case "$r" in
      pass)              count_pass=$((count_pass+1)) ;;
      fail-new)          count_fail_new=$((count_fail_new+1)) ;;
      advisory-new)      count_adv_new=$((count_adv_new+1)) ;;
      fail-unchanged)    count_fail_unch=$((count_fail_unch+1)) ;;
      fallback-no-diagnose) count_fb_nd=$((count_fb_nd+1)) ;;
      fallback-tool-missing) count_fb_tm=$((count_fb_tm+1)) ;;
      skip-arm-off|skip-scope) count_skip=$((count_skip+1)) ;;
    esac
    if [[ "$lat" -gt 0 ]]; then
      total_lat=$((total_lat+lat)); n_lat=$((n_lat+1))
    fi
  done < <(jq -c --arg a "$arm" 'select(.arm==$a)' "$TELEMETRY" 2>/dev/null)

  mean_lat=0
  [[ "$n_lat" -gt 0 ]] && mean_lat=$((total_lat/n_lat))

  printf "%-8s  %-20s  %5d  %5d  %5d  %5d  %5d  %5d  %5d  %12d  %s\n" \
    "$arm" "(all)" \
    "$count_pass" "$count_fail_new" "$count_adv_new" "$count_fail_unch" \
    "$count_fb_nd" "$count_fb_tm" "$count_skip" \
    "$mean_lat" \
    "$([ "$arm" = "on" ] && echo "$count_fail_new new breakages caught" || echo "n/a (arm off)")"
done

echo "==============================================================================="
echo ""
echo "Legend:"
echo "  fail-n  = fail-new       (new breakage at L; forces Claude to address)"
echo "  adv-n   = advisory-new   (new breakage at M; non-blocking advisory)"
echo "  fail-u  = fail-unchanged (same failure as last run; suppressed)"
echo "  fb-nd   = fallback-no-diagnose (no diagnose entry for language)"
echo "  fb-tm   = fallback-tool-missing (diagnose binary not on PATH)"
echo "  skip    = skipped (arm=off or S-complexity scope gate)"
echo "  would-be-rework-catches = fail-new under arm=on (breakages arm=off let through)"
echo ""
echo "NOTE: Real token/turn cost requires accumulated real sessions via"
echo "      tonys-agent-telemetry. This harness measures oracle differential only."
