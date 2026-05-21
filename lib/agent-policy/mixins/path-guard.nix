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

  # Build case statements from patterns
  dotenvCases = lib.filter (p: lib.hasPrefix ".env" p) patterns;
  dirCases = lib.filter (p: lib.hasSuffix "/*" p) patterns;

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

      # Dotenv files
      case "$BASENAME" in
        ${lib.concatStringsSep "|" (map (p: lib.removePrefix "" p) dotenvCases)})
          echo "[PATH-GUARD:${name}] Blocked: dotenv file ($FILE_PATH)."
          exit 2 ;;
      esac

      # Private keys
      case "$BASENAME" in
        *.pem|*.key|*.p12|*.pfx|*.jks|*.keystore|id_rsa|id_ed25519|id_ecdsa)
          echo "[PATH-GUARD:${name}] Blocked: private key ($FILE_PATH)."
          exit 2 ;;
      esac

      # Credential files
      case "$BASENAME" in
        credentials|credentials.json|service-account*.json|*-credentials.*)
          echo "[PATH-GUARD:${name}] Blocked: credentials ($FILE_PATH)."
          exit 2 ;;
      esac

      # Sensitive directories
      case "$FILE_PATH" in
        ${lib.concatStringsSep "|" (map (p: "*/" + lib.removeSuffix "/*" p + "/*") dirCases)})
          echo "[PATH-GUARD:${name}] Blocked: sensitive directory ($FILE_PATH)."
          exit 2 ;;
      esac

      # Token/auth files
      case "$BASENAME" in
        .netrc|.npmrc|.pypirc|token|token.json|auth.json)
          echo "[PATH-GUARD:${name}] Blocked: auth token ($FILE_PATH)."
          exit 2 ;;
      esac

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
