# Agent Policy Contract Assertions — Build-time violation detection
# Fails `nix build` if any provider violates contract invariants.
{
  config,
  lib,
  ...
}: let
  providers = config.agentPolicy.providers;
  providerNames = lib.attrNames providers;

  # Helper: check a predicate across all enabled providers
  forAllEnabled = pred:
    lib.all (name: let p = providers.${name}; in !p.enable || pred name p) providerNames;
in {
  config.assertions = [
    # Strategy lint requires a peer review provider
    {
      assertion =
        forAllEnabled (_: p:
          !p.strategyLint.enabled || p.strategyLint.peerReviewProvider != null);
      message = "[AgentPolicy] strategyLint.enabled=true requires peerReviewProvider to be set";
    }

    # Peer review provider must reference an existing provider
    {
      assertion = forAllEnabled (_: p:
        !p.strategyLint.enabled
        || p.strategyLint.peerReviewProvider == null
        || lib.hasAttr p.strategyLint.peerReviewProvider providers);
      message = "[AgentPolicy] strategyLint.peerReviewProvider references a non-existent provider";
    }

    # Phase enforcement requires at least one gated tool
    {
      assertion =
        forAllEnabled (_: p:
          !p.phases.enforced || p.phases.gatedTools != []);
      message = "[AgentPolicy] phases.enforced=true but gatedTools is empty";
    }

    # Oracle requires at least one health check
    {
      assertion =
        forAllEnabled (_: p:
          !p.oracle.enabled || p.oracle.healthChecks != []);
      message = "[AgentPolicy] oracle.enabled=true but no healthChecks defined";
    }

    # Async requires at least one background task
    {
      assertion =
        forAllEnabled (_: p:
          !p.async.enabled || p.async.backgroundTasks != []);
      message = "[AgentPolicy] async.enabled=true but no backgroundTasks defined";
    }

    # Strategy lint sections must not be empty when enabled
    {
      assertion =
        forAllEnabled (_: p:
          !p.strategyLint.enabled || p.strategyLint.requiredSections != []);
      message = "[AgentPolicy] strategyLint.enabled=true but requiredSections is empty";
    }
  ];
}
