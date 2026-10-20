{
  lib,
  pkgs,
  homeConfigs,
  ...
}:
lib.mapAttrs' (profileName: homeConfig: let
  cfg = homeConfig.config.programs.tonys-agent-harness;
  activation = homeConfig.config.home.activation.reconcileAgentHarness.data;
  normalized = cfg.normalizedConfig;
  normalizedFile = homeConfig.config.xdg.configFile."agent-harness/normalized.json".source;
in
  lib.nameValuePair "agent-harness-${profileName}" (pkgs.runCommand "agent-harness-${profileName}" {} ''
    set -euo pipefail
    test '${toString cfg.projectRoot}' = '${toString ../.}'
    test '${toString cfg.manifest}' = '${toString ../agent-harness.toml}'
    grep -F '"spec_root":".codex"' '${normalizedFile}'
    grep -F '"codex"' '${normalizedFile}'
    grep -F '"claude"' '${normalizedFile}'
    grep -F '"gemini"' '${normalizedFile}'
    grep -F '"kiro"' '${normalizedFile}'
    grep -F 'harness export' <<'SCRIPT'
    ${activation}
    SCRIPT
    grep -F 'reconcile-guides' <<'SCRIPT'
    ${activation}
    SCRIPT
    test '${if normalized.permissions.single_writer then "true" else "false"}' = true
    test '${normalized.permissions.secret_access}' = deny
    test '${if normalized.project.guides.enabled then "true" else "false"}' = true
    touch "$out"
  ''))
homeConfigs
