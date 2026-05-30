# Mixin: Security Path Guard
# Generates PreToolUse hook that blocks access to sensitive file patterns.
# Patterns sourced from agentPolicy.global.sensitivePatterns (SSoT).
{
  config,
  lib,
  pkgs,
  ...
}: let
  patterns = config.agentPolicy.global.sensitivePatterns;
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

      INPUT=$(cat)
      TOOL_NAME=$(echo "$INPUT" | $JQ -r '.tool_name // empty' 2>/dev/null)
      TOOL_INPUT=$(echo "$INPUT" | $JQ -r '.tool_input // empty' 2>/dev/null)

      FILE_PATH=""
      case "$TOOL_NAME" in
        Read|Write|Edit) FILE_PATH=$(echo "$TOOL_INPUT" | $JQ -r '.file_path // empty' 2>/dev/null) ;;
        *) exit 0 ;;
      esac
      [[ -z "$FILE_PATH" ]] && exit 0

      FILE_PATH=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
      BASENAME=$(basename "$FILE_PATH")
      ${lib.optionalString (namePatterns != []) ''
        case "$BASENAME" in
          ${lib.concatStringsSep "|" namePatterns})
            echo "[PATH-GUARD:${name}] Blocked: sensitive file ($FILE_PATH)."
            exit 2 ;;
        esac
      ''}
      ${lib.optionalString (dirPatterns != []) ''
        case "$FILE_PATH" in
          ${lib.concatStringsSep "|" (map (p: "*/" + lib.removeSuffix "/*" p + "/*") dirPatterns)})
            echo "[PATH-GUARD:${name}] Blocked: sensitive directory ($FILE_PATH)."
            exit 2 ;;
        esac
      ''}
      ${lib.optionalString (pathPatterns != []) ''
        case "$FILE_PATH" in
          ${lib.concatStringsSep "|" (map (p: "*/" + p) pathPatterns)})
            echo "[PATH-GUARD:${name}] Blocked: sensitive path ($FILE_PATH)."
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
        matcher = "Write|Edit|Read";
        script = mkScript name prov;
      })
      enabledProviders;
  };
}
