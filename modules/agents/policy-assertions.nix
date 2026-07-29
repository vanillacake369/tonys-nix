# Agent Policy Contract Assertions — Build-time violation detection
# Fails `nix build` if any provider violates contract invariants.
{
  config,
  lib,
  ...
}: let
  providers = config.agentPolicy.providers;
  providerRuntime = config.agentPolicy._providerRuntime;
  providerNames = lib.attrNames providers;
  registry = config.agentPolicy.registry;
  capabilityNames = lib.attrNames registry.capabilities;
  executorNames = lib.attrNames registry.executors;
  workflowNames = lib.attrNames registry.workflows;
  contextSourceNames = lib.attrNames registry.repository.contextSources;
  mcpServerNames = lib.attrNames (config.programs.mcp.servers or {});
  mcpMetadataNames = lib.attrNames config.agentPolicy.tools.mcp;

  executorsForCapability = capability:
    lib.filter (name: builtins.elem capability registry.executors.${name}.capabilities) executorNames;
  workflowPhaseNames = workflow: lib.attrNames workflow.phases;
  markerRefsValid = workflow: phase:
    lib.all (
      group:
        lib.all (
          ref:
            builtins.elem ref.phase (workflowPhaseNames workflow)
            && ref.result != ""
        )
        group
    )
    phase.entry;

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

    # Every enabled provider needs runtime hook render metadata.
    {
      assertion =
        forAllEnabled (name: _:
          lib.hasAttr name providerRuntime);
      message = "[AgentPolicy] enabled provider is missing agentPolicy._providerRuntime.<name>";
    }

    # Every workflow required capability must exist and be bound to at least one executor.
    {
      assertion =
        lib.all (
          workflowName: let
            workflow = registry.workflows.${workflowName};
          in
            lib.all (
              capability:
                builtins.elem capability capabilityNames
                && executorsForCapability capability != []
            )
            workflow.requiredCapabilities
        )
        workflowNames;
      message = "[AgentPolicy] workflow requiredCapabilities must exist and have at least one executor binding";
    }

    # Read-only capabilities cannot be served by write/destructive executors.
    {
      assertion =
        lib.all (
          capabilityName: let
            capability = registry.capabilities.${capabilityName};
            boundExecutors = executorsForCapability capabilityName;
          in
            !capability.readOnly
            || lib.all (executorName: registry.executors.${executorName}.permission == "read") boundExecutors
        )
        capabilityNames;
      message = "[AgentPolicy] read-only capabilities may only bind to read-only executors";
    }

    # Mutating workflows must declare verification, review, and postmortem evidence.
    {
      assertion =
        lib.all (
          workflowName: let
            workflow = registry.workflows.${workflowName};
          in
            workflow.mutability
            != "mutating"
            || (
              workflow.verifyCommand
              != null
              && workflow.reviewRequired
              && workflow.postmortemRequired
              && builtins.elem "verify-command" workflow.requiredEvidence
              && builtins.elem "review-result" workflow.requiredEvidence
              && builtins.elem "postmortem-or-skip" workflow.requiredEvidence
            )
        )
        workflowNames;
      message = "[AgentPolicy] mutating workflows require verify command plus review/postmortem evidence";
    }

    # High-risk/destructive workflows need independent validation or human approval.
    {
      assertion =
        lib.all (
          workflowName: let
            workflow = registry.workflows.${workflowName};
          in
            !(builtins.elem workflow.risk ["high" "destructive"])
            || workflow.crossValidation
            || workflow.humanApproval
        )
        workflowNames;
      message = "[AgentPolicy] high/destructive workflows require crossValidation or humanApproval";
    }

    # Workflows may only reference declared context sources.
    {
      assertion =
        lib.all (
          workflowName:
            lib.all (source: builtins.elem source contextSourceNames)
            registry.workflows.${workflowName}.mandatoryContext
        )
        workflowNames;
      message = "[AgentPolicy] workflow mandatoryContext references an undeclared context source";
    }

    # Dynamic context sources must carry timestamp/provenance for stale-context audits.
    {
      assertion =
        lib.all (
          sourceName: let
            source = registry.repository.contextSources.${sourceName};
          in
            source.kind
            != "dynamic"
            || (source.timestamp != null && source.provenance != "")
        )
        contextSourceNames;
      message = "[AgentPolicy] dynamic context sources require timestamp and provenance metadata";
    }

    # MCP/tool registry must include operation metadata for every declared MCP server.
    {
      assertion =
        lib.all (serverName: builtins.elem serverName mcpMetadataNames) mcpServerNames;
      message = "[AgentPolicy] every programs.mcp.servers entry needs agentPolicy.tools.mcp metadata";
    }

    {
      assertion =
        lib.all (
          serverName: let
            meta = config.agentPolicy.tools.mcp.${serverName};
          in
            meta.read || meta.write || meta.destructive || meta.network
        )
        mcpMetadataNames;
      message = "[AgentPolicy] MCP metadata entries must declare at least one read/write/destructive/network trait";
    }

    {
      assertion = config.agentPolicy.telemetry.contentCapture == false;
      message = "[AgentPolicy] telemetry.contentCapture must remain false for policy hooks";
    }

    {
      assertion = builtins.elem config.agentPolicy.workflow.defaultWorkflow workflowNames;
      message = "[AgentPolicy] workflow.defaultWorkflow must reference a declared registry workflow";
    }

    {
      assertion =
        lib.all (
          workflowName: let
            workflow = registry.workflows.${workflowName};
          in
            workflow.mutability
            != "mutating"
            || workflow.phases != {}
        )
        workflowNames;
      message = "[AgentPolicy] mutating workflows require a declarative phase graph";
    }

    {
      assertion =
        lib.all (
          workflowName: let
            workflow = registry.workflows.${workflowName};
          in
            lib.all (
              phaseName: markerRefsValid workflow workflow.phases.${phaseName}
            )
            (workflowPhaseNames workflow)
        )
        workflowNames;
      message = "[AgentPolicy] workflow phase entry evidence must reference phases in the same workflow";
    }

    {
      assertion =
        lib.all (
          workflowName: let
            workflow = registry.workflows.${workflowName};
            phases = workflowPhaseNames workflow;
          in
            (workflow.verifyPhase == null || builtins.elem workflow.verifyPhase phases)
            && (workflow.verifyPassNext == null || builtins.elem workflow.verifyPassNext phases)
            && (workflow.verifyFailNext == null || builtins.elem workflow.verifyFailNext phases)
        )
        workflowNames;
      message = "[AgentPolicy] workflow verify transition phases must exist in the declared phase graph";
    }
  ];
}
