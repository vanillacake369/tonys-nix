{
  lib,
  pkgs,
  homeConfigs,
  ...
}:
lib.mapAttrs' (profileName: homeConfig: let
  cfg = homeConfig.config.programs.tonys-agent-harness;
  normalized = cfg.normalizedConfig;
  contract = cfg.consumerContract;
in
  lib.nameValuePair "agent-harness-${profileName}" (pkgs.runCommand "agent-harness-${profileName}" {} ''
    set -euo pipefail
    test '${toString cfg.manifest}' = '${toString ../agent-harness.toml}'
    test '${toString cfg.instruction}' = '${toString ../AGENTS.md}'
    test '${cfg.workspaceRoot}' = '${homeConfig.config.home.homeDirectory}/dev/tonys-nix'
    test '${
      if cfg.secretLauncher.enable
      then "true"
      else "false"
    }' = true
    test '${cfg.secretLauncher.secretsFile}' = '${homeConfig.config.home.homeDirectory}/dev/tonys-nix/secrets/mcp.yaml'
    test -x '${homeConfig.config.home.path}/bin/harness'
    test -x '${homeConfig.config.home.path}/bin/codex'
    test -z '${homeConfig.config.programs.fish.shellAliases.codex or ""}'
    test '${homeConfig.config.programs.fish.shellAliases.cdx}' = 'agent-secret-env codex -s workspace-write -a on-request'
    test '${toString contract.contractVersion}' = 1
    test '${
      if contract.enabled
      then "true"
      else "false"
    }' = true
    test '${builtins.concatStringsSep "," contract.enabledProviders}' = 'codex,claude,gemini,kiro'
    test '${builtins.concatStringsSep "," contract.publicCommands}' = 'validate,doctor,plan,export,verify'
    test '${contract.outputDirectory}' = '${homeConfig.config.home.homeDirectory}/.config/agent-harness/generated'
    test '${normalized.project.spec_root}' = '.codex'
    test '${
      if normalized.permissions.single_writer
      then "true"
      else "false"
    }' = true
    test '${normalized.permissions.secret_access}' = deny
    test '${
      if normalized.project.guides.enabled
      then "true"
      else "false"
    }' = true
    touch "$out"
  ''))
homeConfigs
