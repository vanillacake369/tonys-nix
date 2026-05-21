# Agent Policy IoC Assembler
# Imports contract + assertions + all mixins.
# Assembles mixin-generated hooks into provider-specific settings.
# This is the single entry point — provider modules import only this.
{
  config,
  lib,
  ...
}: let
  hookAdapt = import ./hook-adapters.nix {inherit lib;};
  allHooks = config.agentPolicy._hooks;
  providers = config.agentPolicy.providers;
  enabledProviders = lib.filterAttrs (_: p: p.enable) providers;

  # Per-provider assembled hook configs
  assembledHooks = lib.mapAttrs (_name: prov:
    hookAdapt.${prov.hooks.format} allHooks prov.hooks.timeout)
  enabledProviders;
in {
  imports = [
    ./contract.nix
    ./assertions.nix
    ./mixins/phase-gate.nix
    ./mixins/path-guard.nix
    ./mixins/strategy-lint.nix
    ./mixins/reasoning-trace.nix
    ./mixins/async-handshake.nix
    ./mixins/live-oracle.nix
  ];

  # Expose assembled hooks for provider modules to consume
  options.agentPolicy._assembledHooks = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    default = {};
    internal = true;
    description = "Final assembled hooks per provider, in provider-native format";
  };

  config.agentPolicy._assembledHooks = assembledHooks;

  # Create state directories via activation
  config.home.activation.agentPolicyDirs = lib.mkIf (enabledProviders != {}) (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.agentPolicy.global.stateRoot}"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: prov: ''
          mkdir -p "${config.agentPolicy.global.stateRoot}/phases/${name}"
          mkdir -p "${prov.reasoning.traceDir}/${name}"
          ${lib.optionalString prov.strategyLint.enabled ''
            mkdir -p "${prov.strategyLint.strategyPath}"
          ''}
          ${lib.optionalString prov.async.enabled ''
            mkdir -p "${prov.async.fifoDir}/${name}"
          ''}
        '')
        enabledProviders)}
    ''
  );
}
