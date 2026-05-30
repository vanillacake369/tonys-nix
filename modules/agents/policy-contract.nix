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
  };
}
