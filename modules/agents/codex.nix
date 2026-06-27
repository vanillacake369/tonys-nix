# OpenAI Codex CLI configuration
# Contract implementation: logic verifier role with log-only reasoning
{
  config,
  lib,
  ...
}: let
  providerHooks = import ./policy-provider-hooks.nix {inherit lib;};
  codexHooks = providerHooks.mergeHooks providerHooks.codex (config.agentPolicy._assembledHooks.codex or {});
  sharedContext = builtins.readFile ../../dotfiles/shared/AGENTS.md;
  join = lib.concatStringsSep;

  roles = {
    architect = "Architecture planning and implementation roadmap role.";
    cross-validator = "Independent validation and second-opinion role.";
    implementer = "Code implementation role.";
    refactorer = "Behavior-preserving refactoring role.";
    researcher = "Research, documentation, and large-context analysis role.";
    reviewer = "Code review role.";
    tester = "Test design and implementation role.";
  };

  workflows = {
    architectural-planning = {
      role = "architect";
      description = "Plan substantial changes through architecture discovery and tradeoff analysis.";
    };
    code-implementation = {
      role = "implementer";
      description = "Implement focused code changes after learning local patterns.";
    };
    test-development = {
      role = "tester";
      description = "Create tests that match existing project conventions.";
    };
  };

  roleSkills =
    lib.mapAttrs' (name: description: {
      name = "agent-${name}";
      value = ''
        ---
        name: agent-${name}
        description: ${description}
        ---

        # agent-${name}

        Use this Codex skill when the shared agent guide routes work to `${name}`.
        The shared guide is the behavioral source of truth; this file only binds
        that provider-neutral role to Codex's skill surface.
      '';
    })
    roles;

  workflowSkills = lib.mapAttrs (name: workflow: ''
    ---
    name: ${name}
    description: ${workflow.description}
    ---

    # ${name}

    Use this Codex skill for the `${workflow.role}` workflow described by the
    shared agent guide. The shared guide is the behavioral source of truth; this
    file only binds that provider-neutral workflow to Codex's skill surface.
  '') workflows;

  codexContext = ''
    # Codex Provider Bridge

    The shared agent guide below is the behavioral source of truth. In Codex,
    map Claude-oriented sub-agent references to Codex skills:

    ${join "\n" (lib.mapAttrsToList (name: _: "- `${name}` -> `agent-${name}`") roles)}

    Claude-only tool metadata, model names, colors, and `Agent(...)` calls are
    provider-specific details and do not change the shared behavioral contract.

    ${sharedContext}
  '';
in {
  # Contract: Codex is the logic verifier — log-only reasoning
  agentPolicy.providers.codex = {
    enable = lib.mkDefault config.programs.codex.enable;

    # (A) Log-only reasoning — verification traces saved, not shown
    reasoning.mode = "log-only";
    reasoning.traceDir = "/tmp/agent-traces";
  };

  agentPolicy._providerRuntime.codex.hooks = {
    format = "codex";
    timeout = 5;
  };

  programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    context = codexContext;
    skills = roleSkills // workflowSkills;
    rules.default = ''
      prefix_rule(pattern=["nix", "fmt"], decision="allow")
      prefix_rule(pattern=["nix", "flake", "check"], decision="allow")
      prefix_rule(pattern=["nix", "eval"], decision="allow")
    '';
    settings = {
      hooks = codexHooks;
    };
  };
}
