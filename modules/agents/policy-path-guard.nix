# Mixin: Security Path Guard
# Generates PreToolUse hook that blocks access to sensitive file patterns.
# Patterns sourced from agentPolicy.global.sensitivePatterns (SSoT).
{
  config,
  lib,
  pkgs,
  isDarwin,
  ...
}: let
  patterns = config.agentPolicy.global.sensitivePatterns;
  workflowRuntime = config.agentPolicy.workflow;
  telemetry = config.agentPolicy.telemetry;

  # Platform-branched path canonicalizer (absolute + collapse `..`/symlinks).
  # macOS BSD `realpath` lacks a reliable `-m`; rather than pull in GNU coreutils,
  # Darwin resolves the existing parent dir via a `cd` subshell (no GNU dep) and
  # appends the basename. Linux uses its native GNU `realpath -m`. Both expose:
  # canonicalize <path> → prints a canonical path (falls back to input on failure).
  canonicalizeDef =
    if isDarwin
    then ''
      canonicalize() {
        local _p="$1"
        ( cd "$(dirname "$_p")" 2>/dev/null && printf '%s/%s\n' "$(pwd -P)" "$(basename "$_p")" ) \
          || printf '%s\n' "$_p"
      }
    ''
    else ''
      canonicalize() { realpath -m "$1" 2>/dev/null || printf '%s\n' "$1"; }
    '';
  enabledProviders = lib.filterAttrs (_: p: p.enable) config.agentPolicy.providers;

  # Single source of truth. Three pattern shapes, matched against different
  # parts of the resolved path:
  #   "<dir>/*"  → directory glob              → */<dir>/*
  #   "<a>/<b>*" → explicit path glob (has /)  → */<a>/<b>*
  #   "<name>"   → basename glob
  dirPatterns = lib.filter (lib.hasSuffix "/*") patterns;
  pathPatterns = lib.filter (p: lib.hasInfix "/" p && !lib.hasSuffix "/*" p) patterns;
  namePatterns = lib.filter (p: !lib.hasInfix "/" p) patterns;

  mkScript = name: _prov:
    pkgs.writeShellScript "path-guard-${name}.sh" ''
      set -euo pipefail
      JQ="${lib.getExe' pkgs.jq "jq"}"
      CURL="${lib.getExe pkgs.curl}"
      SHA256SUM="${lib.getExe' pkgs.coreutils "sha256sum"}"
      EVENT_LOG="''${AGENTOPS_EVENT_LOG:-${telemetry.eventLog}}"
      OTLP_ENDPOINT="''${AGENTOPS_OTLP_ENDPOINT:-${telemetry.otlp.endpoint}}"
      mkdir -p "$(dirname "$EVENT_LOG")"

      ${canonicalizeDef}
      sanitize_path() {
        local path="$1"
        case "$path" in
          *".env"*|*"credentials"*|*"secrets/"*|*"secret/"*|*"id_rsa"*|*"token"*|*"keychain"*|*"/.ssh/"*|*"/.gnupg/"*|*"/.aws/"*|*"/.kube/"*)
            printf '[redacted]'
            ;;
          *)
            printf '%s' "$path"
            ;;
        esac
      }

      hash_hex() {
        printf '%s' "$1" | "$SHA256SUM" | awk '{print $1}'
      }

      ${import ./runtime/agentops-event.nix {
        inherit lib telemetry;
        provider = name;
      }}

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | $JQ -r '.tool_name // empty' 2>/dev/null)
      TOOL_INPUT=$(echo "$INPUT" | $JQ -r '.tool_input // empty' 2>/dev/null)
      SESSION_ID=$(echo "$INPUT" | $JQ -r '.session_id // "default"' 2>/dev/null)
      WORKFLOW_ID=$(echo "$INPUT" | $JQ -r '.workflow_id // .metadata.workflow_id // "${workflowRuntime.defaultWorkflow}"' 2>/dev/null)
      SLICE_ID=$(echo "$INPUT" | $JQ -r '.slice_id // .metadata.slice_id // "default"' 2>/dev/null)
      TOOL_CWD=$(echo "$INPUT" | $JQ -r '.cwd // .tool_input.cwd // .metadata.cwd // ""' 2>/dev/null)
      AGENTOPS_EVENT_TYPE="agentops.security_intercept"
      AGENTOPS_HOOK_VERSION="path-guard.v1"
      AGENTOPS_POLICY_SOURCE="agentPolicy.global.sensitivePatterns"

      normalize_bash_paths() {
        printf '%s' "$1" | tr '"'"'"'\'"'"'\"|;&()<>{}[]' '                '
      }

      is_read_style_command() {
        case "$1" in
          *cat[[:space:]]*|*less[[:space:]]*|*more[[:space:]]*|*head[[:space:]]*|*tail[[:space:]]*|*sed[[:space:]]*|*awk[[:space:]]*|*grep[[:space:]]*|*rg[[:space:]]*|*jq[[:space:]]*|*yq[[:space:]]*|*python*open*|*node*"readFile"*) return 0 ;;
          *) return 1 ;;
        esac
      }

      token_might_be_path() {
        case "$1" in
          ""|-*|cat|less|more|head|tail|sed|awk|grep|rg|jq|yq|python|python3|node|open|readFile|printf|echo) return 1 ;;
          *) return 0 ;;
        esac
      }

      token_looks_path_like() {
        case "$1" in
          /*|./*|../*|~/*|.*|*/*|*.*) return 0 ;;
          *) [[ -e "$1" ]] ;;
        esac
      }

      candidate_path() {
        local token="$1"
        case "$token" in
          /*|~/*) printf '%s' "$token" ;;
          *) if [[ -n "$TOOL_CWD" ]]; then printf '%s/%s' "$TOOL_CWD" "$token"; else printf '%s' "$token"; fi ;;
        esac
      }

      skip_pattern_operand() {
        local command="$1"
        local token="$2"
        local skipped="$3"
        case "$command" in
          grep|rg|awk|sed)
            [[ "$skipped" != "1" && "$token" != -* ]]
            ;;
          *)
            return 1
            ;;
        esac
      }

      option_reads_next_file() {
        local command="$1"
        local token="$2"
        case "$command:$token" in
          grep:-f|grep:--file|rg:-f|rg:--file|sed:-f|sed:--file|awk:-f|awk:--file) return 0 ;;
          *) return 1 ;;
        esac
      }

      attached_file_operand() {
        local command="$1"
        local token="$2"
        case "$command:$token" in
          grep:--file=*|rg:--file=*|sed:--file=*|awk:--file=*)
            printf '%s' "''${token#--file=}"
            return 0
            ;;
          grep:-f?*|rg:-f?*|sed:-f?*|awk:-f?*)
            printf '%s' "''${token#-f}"
            return 0
            ;;
          *)
            return 1
            ;;
        esac
      }

      FILE_PATH=""
      case "$TOOL_NAME" in
        Read|Write|Edit) FILE_PATH=$(echo "$TOOL_INPUT" | $JQ -r '.file_path // empty' 2>/dev/null) ;;
        Bash)
          COMMAND=$(echo "$TOOL_INPUT" | $JQ -r '.command // empty' 2>/dev/null)
          if is_read_style_command "$COMMAND"; then
              NORMALIZED=$(normalize_bash_paths "$COMMAND")
              READ_COMMAND=""
              PATTERN_SKIPPED=0
              NEXT_TOKEN_IS_FILE=0
              for TOKEN in $NORMALIZED; do
                FILE_OPERAND=0
                case "$TOKEN" in
                  cat|less|more|head|tail|sed|awk|grep|rg|jq|yq)
                    READ_COMMAND="$TOKEN"
                    PATTERN_SKIPPED=0
                    NEXT_TOKEN_IS_FILE=0
                    continue
                    ;;
                esac
                ATTACHED_FILE="$(attached_file_operand "$READ_COMMAND" "$TOKEN" || true)"
                if [[ -n "$ATTACHED_FILE" ]]; then
                  TOKEN="$ATTACHED_FILE"
                  NEXT_TOKEN_IS_FILE=0
                  FILE_OPERAND=1
                fi
                if [[ "$NEXT_TOKEN_IS_FILE" != "1" ]] && option_reads_next_file "$READ_COMMAND" "$TOKEN"; then
                  NEXT_TOKEN_IS_FILE=1
                  continue
                fi
                token_might_be_path "$TOKEN" || continue
                if [[ "$NEXT_TOKEN_IS_FILE" != "1" && "$FILE_OPERAND" != "1" ]] && skip_pattern_operand "$READ_COMMAND" "$TOKEN" "$PATTERN_SKIPPED"; then
                  PATTERN_SKIPPED=1
                  continue
                fi
                NEXT_TOKEN_IS_FILE=0
                BASENAME="''${TOKEN##*/}"
                ${lib.optionalString (namePatterns != []) ''
        case "$BASENAME" in
          ${lib.concatStringsSep "|" namePatterns})
            FILE_PATH=$(canonicalize "$(candidate_path "$TOKEN")")
            emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "path-guard" "block" "fail" "sensitive-path-read" "$FILE_PATH"
            echo "[PATH-GUARD:${name}] Blocked: sensitive Bash read." >&2
            exit 2 ;;
        esac
      ''}
                token_looks_path_like "$TOKEN" || continue
                FILE_PATH=$(canonicalize "$(candidate_path "$TOKEN")")
                BASENAME="''${FILE_PATH##*/}"
                ${lib.optionalString (dirPatterns != []) ''
        case "$FILE_PATH" in
          ${lib.concatStringsSep "|" (map (p: "*/" + lib.removeSuffix "/*" p + "/*") dirPatterns)})
            emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "path-guard" "block" "fail" "sensitive-path-read" "$FILE_PATH"
            echo "[PATH-GUARD:${name}] Blocked: sensitive Bash read." >&2
            exit 2 ;;
        esac
      ''}
                ${lib.optionalString (pathPatterns != []) ''
        case "$FILE_PATH" in
          ${lib.concatStringsSep "|" (map (p: "*/" + p) pathPatterns)})
            emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "path-guard" "block" "fail" "sensitive-path-read" "$FILE_PATH"
            echo "[PATH-GUARD:${name}] Blocked: sensitive Bash read." >&2
            exit 2 ;;
        esac
      ''}
              done
          fi
          exit 0
          ;;
        *) exit 0 ;;
      esac
      [[ -z "$FILE_PATH" ]] && exit 0

      FILE_PATH=$(canonicalize "$FILE_PATH")
      BASENAME="''${FILE_PATH##*/}"
      ${lib.optionalString (namePatterns != []) ''
        case "$BASENAME" in
          ${lib.concatStringsSep "|" namePatterns})
            emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "path-guard" "block" "fail" "sensitive-path" "$FILE_PATH"
            echo "[PATH-GUARD:${name}] Blocked: sensitive file." >&2
            exit 2 ;;
        esac
      ''}
      ${lib.optionalString (dirPatterns != []) ''
        case "$FILE_PATH" in
          ${lib.concatStringsSep "|" (map (p: "*/" + lib.removeSuffix "/*" p + "/*") dirPatterns)})
            emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "path-guard" "block" "fail" "sensitive-path" "$FILE_PATH"
            echo "[PATH-GUARD:${name}] Blocked: sensitive directory." >&2
            exit 2 ;;
        esac
      ''}
      ${lib.optionalString (pathPatterns != []) ''
        case "$FILE_PATH" in
          ${lib.concatStringsSep "|" (map (p: "*/" + p) pathPatterns)})
            emit_event "$SESSION_ID" "$WORKFLOW_ID" "$SLICE_ID" "unclassified" "PreToolUse" "$TOOL_NAME" "path-guard" "block" "fail" "sensitive-path" "$FILE_PATH"
            echo "[PATH-GUARD:${name}] Blocked: sensitive path." >&2
            exit 2 ;;
        esac
      ''}
      exit 0
    '';
in {
  config.agentPolicy._hooks = lib.mkIf (enabledProviders != {}) {
    path-guard =
      lib.mapAttrs (name: prov: {
        event = "PreToolUse";
        matcher = "Write|Edit|Read|Bash";
        script = mkScript name prov;
      })
      enabledProviders;
  };
}
