#!/usr/bin/env bash
# PreToolUse Guard: Sensitive file access protection
# Blocks Read/Write/Edit on secrets, keys, env files, and credentials.
#
# Exit codes:
#   0 = allow
#   2 = block (sensitive path detected)
#
# This hook runs on PreToolUse for Write|Edit|Read matchers.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty' 2>/dev/null)

# Extract file path from tool input (different field names per tool)
FILE_PATH=""
case "$TOOL_NAME" in
  Read)
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null) ;;
  Write)
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null) ;;
  Edit)
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null) ;;
  *) exit 0 ;;
esac

[[ -z "$FILE_PATH" ]] && exit 0

# Normalize: resolve symlinks and relative paths
FILE_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
BASENAME=$(basename "$FILE_PATH")

# --- Blocklist: patterns that must never be accessed ---

# 1. Dotenv files
case "$BASENAME" in
  .env|.env.*)
    echo "[PATH-GUARD] Blocked: dotenv file ($FILE_PATH). Request user approval first."
    exit 2 ;;
esac

# 2. Private keys and certificates
case "$BASENAME" in
  *.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|id_rsa|id_ed25519|id_ecdsa)
    echo "[PATH-GUARD] Blocked: private key/cert ($FILE_PATH)."
    exit 2 ;;
esac

# 3. Credential files
case "$BASENAME" in
  credentials|credentials.json|service-account*.json|*-credentials.*)
    echo "[PATH-GUARD] Blocked: credentials file ($FILE_PATH)."
    exit 2 ;;
esac

# 4. Directory-based sensitive paths
case "$FILE_PATH" in
  */secrets/*|*/secret/*|*/.ssh/*|*/.gnupg/*|*/.aws/credentials*|*/.kube/config*)
    echo "[PATH-GUARD] Blocked: sensitive directory ($FILE_PATH)."
    exit 2 ;;
esac

# 5. Token/auth files
case "$BASENAME" in
  .netrc|.npmrc|.pypirc|token|token.json|auth.json)
    echo "[PATH-GUARD] Blocked: auth token file ($FILE_PATH)."
    exit 2 ;;
esac

exit 0
