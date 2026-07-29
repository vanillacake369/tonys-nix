# Provider-neutral AgentOps registry.
# Provider modules adapt this data to Claude/Codex/Gemini surfaces; guardrails
# and telemetry read the registry directly.
_: let
  marker = phase: result: {inherit phase result;};
  standardWorkflowPhases = {
    guardrail-create = {
      mutationAllowed = true;
      entry = [];
    };
    guardrail-verify = {
      mutationAllowed = false;
      entry = [[(marker "guardrail-create" "done")]];
    };
    impl = {
      mutationAllowed = true;
      entry = [
        [
          (marker "guardrail-verify" "pass")
          (marker "repair-on-verify-fail" "done")
          (marker "repair-on-review-fail" "done")
        ]
      ];
    };
    verify = {
      mutationAllowed = false;
      entry = [[(marker "impl" "done")]];
    };
    repair-on-verify-fail = {
      mutationAllowed = true;
      entry = [[(marker "verify" "fail")]];
    };
    review = {
      mutationAllowed = false;
      entry = [[(marker "verify" "pass")]];
    };
    repair-on-review-fail = {
      mutationAllowed = true;
      entry = [[(marker "review" "fail")]];
    };
    postmortem = {
      mutationAllowed = true;
      entry = [[(marker "review" "pass")]];
    };
    future-research = {
      mutationAllowed = true;
      entry = [
        [
          (marker "postmortem" "done")
          (marker "postmortem" "skip")
        ]
      ];
    };
    commit = {
      mutationAllowed = true;
      entry = [
        [(marker "verify" "pass")]
        [(marker "review" "pass")]
        [
          (marker "postmortem" "done")
          (marker "postmortem" "skip")
        ]
        [
          (marker "future-research" "done")
          (marker "future-research" "skip")
        ]
      ];
    };
  };
in {
  config.agentPolicy = {
    registry = {
      capabilities = {
        planner = {
          description = "Shape a task into phases, risks, and verification evidence.";
          readOnly = true;
        };
        researcher = {
          description = "Gather repository, documentation, or web context.";
          readOnly = true;
        };
        guardrail-designer = {
          description = "Design or update policy, hook, and assertion guardrails.";
          readOnly = false;
        };
        implementer = {
          description = "Modify source files within the declared repository boundary.";
          readOnly = false;
        };
        tester = {
          description = "Create and run focused verification.";
          readOnly = false;
        };
        reviewer = {
          description = "Inspect finished changes for bugs, regressions, and test gaps.";
          readOnly = true;
        };
        cross-validator = {
          description = "Provide independent validation for high-risk decisions.";
          readOnly = true;
        };
        postmortem-writer = {
          description = "Record outcome, evidence, risks, and follow-up learning.";
          readOnly = false;
        };
      };

      executors = {
        local-shell = {
          kind = "local";
          provider = null;
          capabilities = ["implementer" "tester" "guardrail-designer" "postmortem-writer"];
          permission = "write";
          network = false;
        };
        codex-skill-planner = {
          kind = "codex-skill";
          provider = "codex";
          capabilities = ["planner" "reviewer"];
          permission = "read";
          network = false;
        };
        codex-skill-implementer = {
          kind = "codex-skill";
          provider = "codex";
          capabilities = ["implementer" "tester"];
          permission = "write";
          network = false;
        };
        claude-agent-orchestrator = {
          kind = "claude-agent";
          provider = "claude";
          capabilities = ["guardrail-designer" "implementer" "tester" "postmortem-writer"];
          permission = "write";
          network = false;
        };
        claude-agent-planner = {
          kind = "claude-agent";
          provider = "claude";
          capabilities = ["planner" "reviewer"];
          permission = "read";
          network = false;
        };
        gemini-proxy-researcher = {
          kind = "gemini-proxy";
          provider = "gemini";
          capabilities = ["researcher" "cross-validator"];
          permission = "read";
          network = true;
        };
        codex-cross-validator = {
          kind = "codex-skill";
          provider = "codex";
          capabilities = ["cross-validator" "researcher"];
          permission = "read";
          network = true;
        };
      };

      workflows = {
        agentops-policy-change = {
          requiredCapabilities = ["planner" "guardrail-designer" "implementer" "tester" "reviewer" "postmortem-writer"];
          mutability = "mutating";
          risk = "high";
          requiredEvidence = ["verify-command" "review-result" "postmortem-or-skip"];
          verifyCommand = "nix flake check --no-build";
          reviewRequired = true;
          postmortemRequired = true;
          crossValidation = true;
          mandatoryContext = ["shared-agent-guide" "coding-agent-system" "agent-policy-modules"];
          phases = standardWorkflowPhases;
          verifyPhase = "verify";
          verifyPassNext = "review";
          verifyFailNext = "repair-on-verify-fail";
        };
        code-implementation = {
          requiredCapabilities = ["implementer" "tester" "reviewer"];
          mutability = "mutating";
          risk = "medium";
          requiredEvidence = ["verify-command" "review-result" "postmortem-or-skip"];
          verifyCommand = "nix flake check --no-build";
          reviewRequired = true;
          postmortemRequired = true;
          mandatoryContext = ["shared-agent-guide" "agent-policy-modules"];
          phases = standardWorkflowPhases;
          verifyPhase = "verify";
          verifyPassNext = "review";
          verifyFailNext = "repair-on-verify-fail";
        };
        research-audit = {
          requiredCapabilities = ["researcher" "cross-validator"];
          mutability = "read-only";
          risk = "medium";
          requiredEvidence = ["source-list" "decision-summary"];
          verifyCommand = null;
          reviewRequired = false;
          postmortemRequired = false;
          mandatoryContext = ["shared-agent-guide"];
          phases = {};
        };
        commit = {
          requiredCapabilities = ["tester" "reviewer" "postmortem-writer"];
          mutability = "mutating";
          risk = "high";
          requiredEvidence = ["verify-command" "review-result" "postmortem-or-skip"];
          verifyCommand = "git status --short";
          reviewRequired = true;
          postmortemRequired = true;
          crossValidation = true;
          mandatoryContext = ["shared-agent-guide"];
          phases = standardWorkflowPhases;
          verifyPhase = "verify";
          verifyPassNext = "review";
          verifyFailNext = "repair-on-verify-fail";
        };
      };

      repository = {
        commands = {
          flake-check = {
            command = "nix flake check --no-build";
            description = "Evaluate flake checks without building derivation outputs.";
          };
          guard-tests = {
            command = "nix build --print-out-paths .#checks.$(nix eval --raw --impure --expr builtins.currentSystem).guard-tests --no-link";
            description = "Run pure guard registry tests.";
          };
        };
        invariants = [
          "Agent policy contract options are provider-neutral; provider modules are adapters."
          "Runtime enforcement belongs in Nix-generated hooks and local shell hooks, not telemetry consumers."
          "Telemetry events record summaries, paths, statuses, and decisions; prompt/content capture is off by default."
        ];
        testMatrix = {
          agent-policy = ["flake-check" "guard-tests"];
          hooks = ["flake-check"];
          docs = ["flake-check"];
        };
        contextSources = {
          shared-agent-guide = {
            path = "modules/agents/shared/AGENTS.md";
            kind = "static";
            required = true;
            trustLabel = "repository";
            provenance = "repository";
          };
          coding-agent-system = {
            path = "coding-agent-system.md";
            kind = "static";
            required = true;
            trustLabel = "repository";
            provenance = "repository";
          };
          agent-policy-modules = {
            path = "modules/agents";
            kind = "static";
            required = true;
            trustLabel = "repository";
            provenance = "repository";
          };
          runtime-hook-evidence = {
            path = "/tmp/agent-policy";
            kind = "dynamic";
            required = false;
            trustLabel = "runtime";
            provenance = "local-hooks";
            timestamp = "runtime";
          };
        };
      };
    };

    tools.mcp = {
      context7 = {
        read = true;
        write = false;
        destructive = false;
        network = true;
      };
      playwright = {
        read = true;
        write = true;
        destructive = false;
        network = true;
      };
    };
  };
}
