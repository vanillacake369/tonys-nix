# home-manager module — requires HM context (config.home.activation)
# Agent Policy IoC Assembler
# Imports contract + assertions + all mixins.
# Assembles mixin-generated hooks into provider-specific settings.
# This is the single entry point — provider modules import only this.
{
  config,
  lib,
  ...
}: let
  hookAdapt = import ./policy-hook-adapters.nix {inherit lib;};
  allHooks = config.agentPolicy._hooks;
  providers = config.agentPolicy.providers;
  providerRuntime = config.agentPolicy._providerRuntime;
  enabledProviders = lib.filterAttrs (_: p: p.enable) providers;

  # Per-provider assembled hook configs
  assembledHooks = lib.mapAttrs (name: _prov: let
    runtime = providerRuntime.${name}.hooks or null;
  in
    if runtime == null
    then {}
    else hookAdapt.${runtime.format} allHooks runtime.timeout)
  enabledProviders;
in {
  imports = [
    ./policy-contract.nix
    ./policy-assertions.nix
    ./policy-phase-gate.nix
    ./policy-path-guard.nix
    ./policy-strategy-lint.nix
    ./policy-reasoning-trace.nix
    ./policy-async-handshake.nix
    ./policy-live-oracle.nix
  ];

  # Expose assembled hooks for provider modules to consume
  options.agentPolicy = {
    _providerRuntime = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.hooks = {
          format = lib.mkOption {
            type = lib.types.enum (lib.attrNames (lib.removeAttrs hookAdapt ["groupByProvider" "groupByEvent"]));
            description = "Hook configuration format for this provider";
          };
          timeout = lib.mkOption {
            type = lib.types.int;
            default = 5;
            description = "Default hook timeout in seconds";
          };
        };
      });
      default = {};
      internal = true;
      description = "Provider render metadata consumed by the policy runtime";
    };

    _assembledHooks = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      internal = true;
      description = "Final assembled hooks per provider, in provider-native format";
    };
  };

  config.agentPolicy._assembledHooks = assembledHooks;

  # Create state directories via activation
  config.home.activation.agentPolicyDirs = lib.mkIf (enabledProviders != {}) (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${config.agentPolicy.global.stateRoot}"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: prov: ''
          ${lib.optionalString prov.phases.enforced ''
            mkdir -p "${prov.phases.stateDir}"
          ''}
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
