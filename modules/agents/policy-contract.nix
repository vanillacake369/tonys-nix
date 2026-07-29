# Agent Policy Contract — Interface definition
# All providers must satisfy this option type schema.
# Nix module system acts as the IoC container: options = interface, values = implementation.
{lib, ...}: let
  inherit (lib) mkOption mkEnableOption types;

  # Valid hook lifecycle events — exhaustive enum prevents typo bugs
  hookEventEnum = types.enum [
    "UserPromptSubmit"
    "PreToolUse"
    "PostToolUse"
    "Stop"
    "SubagentStop"
  ];

  healthCheckType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Shell command to run for health verification";
        example = "nix flake check";
      };
      pattern = mkOption {
        type = types.str;
        default = ".*";
        description = "File glob pattern that triggers this check";
      };
      timeout = mkOption {
        type = types.int;
        default = 30;
        description = "Timeout in seconds";
      };
    };
  };

  providerModule = types.submodule {
    options = {
      enable = mkEnableOption "this agent provider";

      # (A) Reasoning Trace — separates chain-of-thought from final output
      reasoning = {
        mode = mkOption {
          type = types.enum ["silent" "verbose" "log-only"];
          default = "verbose";
          description = ''
            silent:   internal reasoning hidden, only decisions shown
            verbose:  full reasoning visible (default for research agents)
            log-only: reasoning written to traceDir, not shown in conversation
          '';
        };
        traceDir = mkOption {
          type = types.str;
          default = "/tmp/agent-traces";
          description = "Directory for reasoning trace logs";
        };
      };

      # (B) Async Sub-Agent Handshake
      async = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this provider supports background task execution";
        };
        backgroundTasks = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Named tasks this provider can run asynchronously";
          example = ["strategy-review" "blindspot-audit"];
        };
        handshakeProtocol = mkOption {
          type = types.enum ["poll" "fifo" "callback"];
          default = "fifo";
          description = "IPC mechanism for async result delivery";
        };
        fifoDir = mkOption {
          type = types.str;
          default = "/tmp/agent-handshake";
          description = "Directory for FIFO pipes (when protocol = fifo)";
        };
      };

      # (D) Live Verification Oracle
      oracle = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Enable runtime verification beyond lint/build";
        };
        healthChecks = mkOption {
          type = types.listOf healthCheckType;
          default = [];
          description = "Commands to run for live verification";
        };
        streamAnalysis = mkOption {
          type = types.bool;
          default = false;
          description = "Analyze stdout/stderr in real-time during verification";
        };
      };

      # (E) Phase State Machine Adapter
      phases = {
        enforced = mkOption {
          type = types.bool;
          default = false;
          description = "Enforce phase-locked state machine via hook gates";
        };
        stateDir = mkOption {
          type = types.str;
          default = "/tmp/agent-phases";
          description = "Directory for phase state files";
        };
        gatedTools = mkOption {
          type = types.listOf types.str;
          default = ["Write" "Edit"];
          description = "Tools blocked until phase approval";
        };
      };

      # (F) Strategy Linter / LSP Hook Gate
      strategyLint = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Require strategy document validation before execution";
        };
        requiredSections = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Sections that must appear in strategy document";
          example = ["pre-mortem" "tradeoffs" "peer-review"];
        };
        peerReviewProvider = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Provider name to auto-invoke for strategy review";
        };
        strategyPath = mkOption {
          type = types.str;
          default = "/tmp/agent-strategy";
          description = "Directory where strategy documents are written";
        };
      };
    };
  };
  # Internal hook type — produced by mixins, consumed by policy.nix
  hookEntryType = types.submodule {
    options = {
      event = mkOption {type = hookEventEnum;};
      matcher = mkOption {
        type = types.str;
        default = "";
      };
      script = mkOption {type = types.either types.path types.str;};
      mixin = mkOption {
        type = types.str;
        default = "unknown";
      };
    };
  };

  capabilityType = types.submodule {
    options = {
      description = mkOption {
        type = types.str;
        default = "";
        description = "Human-readable capability contract";
      };
      readOnly = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this capability must not mutate repository or external state";
      };
    };
  };

  executorType = types.submodule {
    options = {
      provider = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Provider adapter used by this executor, when any";
      };
      kind = mkOption {
        type = types.str;
        default = "local";
        description = "Executor implementation class, e.g. local, codex-skill, claude-agent, gemini-proxy";
      };
      capabilities = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Provider-neutral capabilities this executor can satisfy";
      };
      permission = mkOption {
        type = types.enum ["read" "write" "destructive"];
        default = "read";
        description = "Maximum filesystem or external mutation permission for this executor";
      };
      network = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this executor may use networked tools";
      };
    };
  };

  markerRefType = types.submodule {
    options = {
      phase = mkOption {
        type = types.str;
        description = "Phase that must have produced evidence";
      };
      result = mkOption {
        type = types.str;
        description = "Required evidence result for the phase";
      };
    };
  };

  phaseSpecType = types.submodule {
    options = {
      mutationAllowed = mkOption {
        type = types.bool;
        default = false;
        description = "Whether repository or external mutation tools may run in this phase";
      };
      entry = mkOption {
        type = types.listOf (types.listOf markerRefType);
        default = [];
        description = ''
          Entry evidence requirements. The outer list is AND; each inner list is
          OR. An empty outer list means the phase can be entered without marker
          evidence.
        '';
      };
    };
  };

  workflowType = types.submodule {
    options = {
      requiredCapabilities = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Capabilities required to complete this workflow";
      };
      mutability = mkOption {
        type = types.enum ["read-only" "mutating"];
        default = "read-only";
        description = "Whether this workflow may change repository or external state";
      };
      risk = mkOption {
        type = types.enum ["low" "medium" "high" "destructive"];
        default = "low";
        description = "Highest expected operational risk";
      };
      requiredEvidence = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Evidence artifacts the workflow must produce";
      };
      verifyCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Machine-runnable verification command, when available";
      };
      reviewRequired = mkOption {
        type = types.bool;
        default = false;
        description = "Whether a review pass is required before completion";
      };
      postmortemRequired = mkOption {
        type = types.bool;
        default = false;
        description = "Whether postmortem evidence or an explicit skip reason is required";
      };
      humanApproval = mkOption {
        type = types.bool;
        default = false;
        description = "Whether a human approval gate is required";
      };
      crossValidation = mkOption {
        type = types.bool;
        default = false;
        description = "Whether independent cross-validation is required";
      };
      mandatoryContext = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Context source ids that must be consulted or explicitly waived";
      };
      phases = mkOption {
        type = types.attrsOf phaseSpecType;
        default = {};
        description = "Workflow-specific phase graph used to generate provider-native runtime gates";
      };
      verifyPhase = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Phase where verification command results should be observed";
      };
      verifyPassNext = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Phase to enter after a successful verification command";
      };
      verifyFailNext = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Phase to enter after a failed verification command";
      };
    };
  };

  contextSourceType = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        description = "Repository-relative or absolute context path";
      };
      kind = mkOption {
        type = types.enum ["static" "dynamic"];
        default = "static";
        description = "Whether this context source is stable text or runtime evidence";
      };
      required = mkOption {
        type = types.bool;
        default = false;
        description = "Whether workflows should treat this source as mandatory by default";
      };
      trustLabel = mkOption {
        type = types.enum ["system" "repository" "generated" "runtime" "external" "untrusted"];
        default = "repository";
        description = "Trust tier used during context assembly";
      };
      provenance = mkOption {
        type = types.str;
        default = "declared-in-nix";
        description = "Where this source declaration came from";
      };
      timestamp = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Timestamp for stale-prone dynamic sources";
      };
    };
  };

  mcpMetadataType = types.submodule {
    options = {
      read = mkOption {
        type = types.bool;
        default = false;
        description = "Tool can read local or external data";
      };
      write = mkOption {
        type = types.bool;
        default = false;
        description = "Tool can mutate local or external data";
      };
      destructive = mkOption {
        type = types.bool;
        default = false;
        description = "Tool can perform destructive actions";
      };
      network = mkOption {
        type = types.bool;
        default = false;
        description = "Tool requires network access";
      };
    };
  };
in {
  options.agentPolicy = {
    providers = mkOption {
      type = types.attrsOf providerModule;
      default = {};
      description = "Per-provider agent policy contract implementations";
    };

    # Internal: mixin-generated hooks (not user-facing)
    _hooks = mkOption {
      type = types.attrsOf (types.attrsOf hookEntryType);
      default = {};
      internal = true;
      description = "Generated hooks: { <mixin-name>.<provider-name> = hookEntry; }";
    };

    # Shared state — cross-cutting concerns
    global = {
      stateRoot = mkOption {
        type = types.str;
        default = "/tmp/agent-policy";
        description = "Root directory for all agent policy state files";
      };
      sensitivePatterns = mkOption {
        type = types.listOf types.str;
        default = [
          # dotenv
          ".env"
          ".env.*"
          # private keys / keystores
          "*.pem"
          "*.key"
          "*.p12"
          "*.pfx"
          "*.jks"
          "*.keystore"
          "id_rsa"
          "id_ed25519"
          "id_ecdsa"
          # credentials
          "credentials"
          "credentials.json"
          "service-account*.json"
          "*-credentials.*"
          # auth tokens
          ".netrc"
          ".npmrc"
          ".pypirc"
          "token"
          "token.json"
          "auth.json"
          # sensitive directories / paths (matched against the full resolved path)
          "secrets/*"
          "secret/*"
          ".ssh/*"
          ".gnupg/*"
          ".aws/credentials*"
          ".kube/config*"
        ];
        description = ''
          File patterns blocked by path-guard across all providers (single source of truth).
          Entries ending in `/*` are directory globs and entries containing `/` are path
          globs (both matched against the resolved path); all others match the basename.
        '';
      };
      maxRetries = mkOption {
        type = types.int;
        default = 3;
        description = "Max consecutive failures before escalation";
      };
    };

    registry = {
      capabilities = mkOption {
        type = types.attrsOf capabilityType;
        default = {};
        description = "Provider-neutral capability registry";
      };
      executors = mkOption {
        type = types.attrsOf executorType;
        default = {};
        description = "Executor registry binding providers and tools to capabilities";
      };
      workflows = mkOption {
        type = types.attrsOf workflowType;
        default = {};
        description = "Workflow registry with capability, risk, evidence, and verification contracts";
      };
      repository = {
        commands = mkOption {
          type = types.attrsOf (types.submodule {
            options = {
              command = mkOption {type = types.str;};
              description = mkOption {
                type = types.str;
                default = "";
              };
            };
          });
          default = {};
          description = "Machine-readable repository command map";
        };
        invariants = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Architecture invariants agents must preserve";
        };
        testMatrix = mkOption {
          type = types.attrsOf (types.listOf types.str);
          default = {};
          description = "Mapping from change area to verification commands";
        };
        contextSources = mkOption {
          type = types.attrsOf contextSourceType;
          default = {};
          description = "Context inventory with provenance and trust metadata";
        };
      };
    };

    tools.mcp = mkOption {
      type = types.attrsOf mcpMetadataType;
      default = {};
      description = "Security metadata for MCP servers declared under programs.mcp.servers";
    };

    workflow = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Generate provider-native workflow phase gates from agentPolicy.registry.workflows";
      };
      stateDir = mkOption {
        type = types.str;
        default = "/tmp/agent-policy/workflows";
        description = "Directory containing per-session workflow phase and evidence markers";
      };
      defaultWorkflow = mkOption {
        type = types.str;
        default = "code-implementation";
        description = "Workflow id used when hook input does not include workflow metadata";
      };
      gatedTools = mkOption {
        type = types.listOf types.str;
        default = ["Write" "Edit" "NotebookEdit" "Bash"];
        description = "Tools inspected by the generated workflow phase gate";
      };
    };

    telemetry = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Emit provider-neutral AgentOpsEvent JSONL from policy hooks";
      };
      schemaVersion = mkOption {
        type = types.str;
        default = "agentops.event.v1";
        description = "AgentOpsEvent schema version";
      };
      eventLog = mkOption {
        type = types.str;
        default = "/tmp/agent-policy/events.jsonl";
        description = "Local JSONL event sink. Content capture stays off by default.";
      };
      contentCapture = mkOption {
        type = types.bool;
        default = false;
        description = "Whether telemetry may include raw prompts, command output, or file content. Must stay false for the policy hooks.";
      };
      otlp = {
        enabled = mkOption {
          type = types.bool;
          default = false;
          description = "Also emit AgentOpsEvent as OTLP/JSON spans to a local collector";
        };
        endpoint = mkOption {
          type = types.str;
          default = "http://127.0.0.1:4318/v1/traces";
          description = "OTLP/HTTP JSON traces endpoint";
        };
      };
    };
  };
}
