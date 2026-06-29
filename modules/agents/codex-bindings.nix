# Codex provider bindings derived from the shared agent guide.
# Pure data/functions so tests can validate provider outporting without
# evaluating a full home-manager configuration.
{lib}: let
  join = lib.concatStringsSep;
  workflowBindings = import ./workflow-bindings.nix {inherit lib;};

  mkReadProfile = {
    network ? false,
    write ? false,
  }: {
    filesystem = {
      ":workspace_roots"."." =
        if write
        then "write"
        else "read";
      ":workspace_roots"."**/.env*" = "deny";
      ":workspace_roots"."**/*credentials*" = "deny";
      glob_scan_max_depth = 8;
    };
    network = {
      enabled = network;
      mode = "limited";
      domains = lib.optionalAttrs network {
        "*" = "allow";
      };
    };
  };

  roles = {
    architect = {
      description = "Architecture planning and implementation roadmap role.";
      permissionProfile = "agent-architect";
    };
    cross-validator = {
      description = "Independent validation and second-opinion role.";
      permissionProfile = "agent-cross-validator";
    };
    implementer = {
      description = "Code implementation role.";
      permissionProfile = "agent-implementer";
    };
    refactorer = {
      description = "Behavior-preserving refactoring role.";
      permissionProfile = "agent-refactorer";
    };
    researcher = {
      description = "Research, documentation, and large-context analysis role.";
      permissionProfile = "agent-researcher";
    };
    reviewer = {
      description = "Code review role.";
      permissionProfile = "agent-reviewer";
    };
    tester = {
      description = "Test design and implementation role.";
      permissionProfile = "agent-tester";
    };
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

  permissionProfiles = {
    default = mkReadProfile {write = true;};
    agent-architect = mkReadProfile {};
    agent-cross-validator = mkReadProfile {network = true;};
    agent-implementer = mkReadProfile {write = true;};
    agent-refactorer = mkReadProfile {write = true;};
    agent-researcher = mkReadProfile {network = true;};
    agent-reviewer = mkReadProfile {};
    agent-tester = mkReadProfile {write = true;};
  };

  mkDeveloperInstructions = name: role: ''
    You are the Codex ${name} subagent.

    ${role.description}

    Follow the shared AGENTS.md contract for orchestration, escalation, and
    reporting. Keep work scoped to this role. Do not revert edits made by
    other agents or the user.
  '';

  roleSkills =
    lib.mapAttrs' (name: role: {
      name = "agent-${name}";
      value = ''
        ---
        name: agent-${name}
        description: ${role.description}
        ---

        # agent-${name}

        Use this Codex skill when the shared agent guide routes work to `${name}`.
        The shared guide is the behavioral source of truth; this file only binds
        that provider-neutral role to Codex's skill surface. Runtime subagent
        behavior is bound through `~/.codex/agents/${name}.toml`, which selects
        the `${role.permissionProfile}` permission profile.
      '';
    })
    roles;

  workflowSkills =
    lib.mapAttrs (name: workflow: ''
      ---
      name: ${name}
      description: ${workflow.description}
      ---

      # ${name}

      Use this Codex skill for the `${workflow.role}` workflow described by the
      shared agent guide. The shared guide is the behavioral source of truth; this
      file only binds that provider-neutral workflow to Codex's skill surface.
    '')
    workflows;

  mkContext = sharedContext: ''
    # Codex Provider Bridge

    The shared agent guide below is the behavioral source of truth. In Codex,
    map Claude-oriented sub-agent references to Codex skills:

    ${join "\n" (lib.mapAttrsToList (name: role: "- `${name}` -> `agent-${name}` / permission profile `${role.permissionProfile}`") roles)}

    Claude-only tool metadata, model names, colors, and `Agent(...)` calls are
    provider-specific details and do not change the shared behavioral contract.

    ${sharedContext}
  '';

  customAgents =
    lib.mapAttrs (name: role: {
      inherit name;
      description = role.description;
      developer_instructions = mkDeveloperInstructions name role;
      model = "gpt-5.5";
      default_permissions = role.permissionProfile;
    })
    roles;
in {
  inherit roles workflows permissionProfiles roleSkills workflowSkills customAgents mkContext;
  inherit (workflowBindings) commandWorkflows;

  skills = roleSkills // workflowSkills // workflowBindings.codexSkills;

  mkSettings = {
    hooks ? {},
    mcp ? {},
  }: {
    default_permissions = "default";
    permissions = permissionProfiles;
    inherit hooks;
    mcp_servers = mcp;
  };
}
