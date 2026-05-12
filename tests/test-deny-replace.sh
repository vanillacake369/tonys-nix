#!/usr/bin/env bash
# Tests for Deny + Replace multi-provider delegation strategy
# Usage: bash tests/test-deny-replace.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PASS=0
FAIL=0
TOTAL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected to contain: '$needle'"
    echo "    actual (first 300 chars): '${haystack:0:300}'"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  TOTAL=$((TOTAL + 1))
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected NOT to contain: '$needle'"
    FAIL=$((FAIL + 1))
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  TOTAL=$((TOTAL + 1))
  if [[ -f "$path" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc (file not found: $path)"
    FAIL=$((FAIL + 1))
  fi
}

# ===========================================================================
# 1. Deny Configuration
# ===========================================================================

echo "=== 1. Deny Configuration ==="

settings=$(cat "$REPO_ROOT/dotfiles/claude/settings.json")

# 1-1. general-purpose is denied
deny_list=$(echo "$settings" | jq -r '.permissions.deny[]' 2>/dev/null)
assert_contains "general-purpose is denied" "Agent(general-purpose)" "$deny_list"

# 1-2. Explore is NOT denied (should remain usable)
assert_not_contains "Explore is not denied" "Agent(Explore)" "$deny_list"

# 1-3. Plan is NOT denied
assert_not_contains "Plan is not denied" "Agent(Plan)" "$deny_list"

echo ""

# ===========================================================================
# 2. Researcher Agent Structure
# ===========================================================================

echo "=== 2. Researcher Agent ==="

researcher_path="$REPO_ROOT/dotfiles/claude/agents/researcher.md"
assert_file_exists "researcher.md exists" "$researcher_path"

if [[ -f "$researcher_path" ]]; then
  researcher=$(cat "$researcher_path")

  # 2-1. Frontmatter: model is haiku (cheap coordination)
  assert_contains "researcher uses haiku model" "model: haiku" "$researcher"

  # 2-2. Frontmatter: has Bash tool (for curl)
  assert_contains "researcher has Bash tool" "Bash" "$researcher"

  # 2-3. Frontmatter: disallows Agent (no recursive subagents)
  assert_contains "researcher disallows Agent" "disallowedTools" "$researcher"

  # 2-4. Body: references proxy URL
  assert_contains "researcher references proxy" "127.0.0.1:4001" "$researcher"

  # 2-5. Body: uses gemini model
  assert_contains "researcher routes to gemini" "gemini" "$researcher"
fi

echo ""

# ===========================================================================
# 3. Cross-Validator Agent Structure
# ===========================================================================

echo "=== 3. Cross-Validator Agent ==="

cv_path="$REPO_ROOT/dotfiles/claude/agents/cross-validator.md"
assert_file_exists "cross-validator.md exists" "$cv_path"

if [[ -f "$cv_path" ]]; then
  cv=$(cat "$cv_path")

  # 3-1. model is haiku
  assert_contains "cross-validator uses haiku model" "model: haiku" "$cv"

  # 3-2. disallows Agent
  assert_contains "cross-validator disallows Agent" "disallowedTools" "$cv"

  # 3-3. references proxy
  assert_contains "cross-validator references proxy" "127.0.0.1:4001" "$cv"

  # 3-4. uses different model than researcher (for cross-validation value)
  assert_contains "cross-validator routes to gpt" "gpt" "$cv"
fi

echo ""

# ===========================================================================
# 4. AGENTS.md Routing Rules
# ===========================================================================

echo "=== 4. AGENTS.md Routing Rules ==="

agents_md=$(cat "$REPO_ROOT/dotfiles/shared/AGENTS.md")

# 4-1. Mentions researcher agent
assert_contains "AGENTS.md mentions researcher" "researcher" "$agents_md"

# 4-2. Mentions cross-validator agent
assert_contains "AGENTS.md mentions cross-validator" "cross-validator" "$agents_md"

# 4-3. Explicitly states general-purpose is denied
assert_contains "AGENTS.md states deny" "denied" "$agents_md"

# 4-4. Has routing table or clear delegation rules
assert_contains "AGENTS.md has routing guidance" "Routing" "$agents_md"

echo ""

# ===========================================================================
# 5. Proxy Connectivity (integration)
# ===========================================================================

echo "=== 5. Proxy Connectivity ==="

# 5-1. Proxy is reachable
proxy_status=$(curl -s --max-time 3 http://127.0.0.1:4001/v1/models 2>/dev/null | jq -r '.data | length' 2>/dev/null || echo "0")
if [[ "$proxy_status" -gt 0 ]]; then
  echo "  PASS: proxy is reachable ($proxy_status models)"
  PASS=$((PASS + 1))
else
  echo "  SKIP: proxy not running (integration test)"
  # Don't count as failure - proxy may not be running in CI
fi
TOTAL=$((TOTAL + 1))

# 5-2. Gemini model available on proxy
if [[ "$proxy_status" -gt 0 ]]; then
  models=$(curl -s --max-time 3 http://127.0.0.1:4001/v1/models 2>/dev/null | jq -r '.data[].id' 2>/dev/null)
  assert_contains "gemini-2.5-flash-lite available" "gemini-2.5-flash-lite" "$models"
  assert_contains "gpt-5.4-mini available" "gpt-5.4-mini" "$models"
fi

echo ""

# ===========================================================================
# 6. No Conflicting Agent Names
# ===========================================================================

echo "=== 6. Agent Name Conflicts ==="

# 6-1. No custom agent named "general-purpose" (would shadow the deny)
assert_eq "no general-purpose custom agent" "false" \
  "$(test -f "$REPO_ROOT/dotfiles/claude/agents/general-purpose.md" && echo true || echo false)"

# 6-2. All custom agents have unique names
agent_names=$(grep -h '^name:' "$REPO_ROOT/dotfiles/claude/agents/"*.md 2>/dev/null | sort)
unique_names=$(echo "$agent_names" | sort -u)
assert_eq "all agent names are unique" "$agent_names" "$unique_names"

echo ""

# ===========================================================================
# Summary
# ===========================================================================

echo "==========================================="
echo "Results: $PASS passed, $FAIL failed, $TOTAL total"
echo "==========================================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
