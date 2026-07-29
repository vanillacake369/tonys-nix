# Guard tests: core invariants only (discovery, SSoT data, pure mappers).
# Detailed output-format / platform / policy-internal tests were intentionally
# dropped — build-time assertions + `nix flake check` + per-platform builds
# cover the rest. Keep this file small so the structure stays flexible.
# Run: nix build --print-out-paths .#checks.<system>.guard-tests --no-link
# Run verbose:
#   nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); collectTests = (import ./lib/collect-tests.nix { lib = flake.inputs.nixpkgs.lib; }) ./tests; in (collectTests { lib = flake.inputs.nixpkgs.lib; }).results'
{lib}: let
  # --- Fixtures ---
  mcpAdapt = import ../modules/agents/adapters/mcp.nix {inherit lib;};
  hookAdapt = import ../modules/agents/adapters/hooks.nix {inherit lib;};
  workflowBindings = import ../modules/agents/adapters/workflows.nix {inherit lib;};
  codexBindings = import ../modules/agents/providers/codex/bindings.nix {inherit lib;};
  claudeBaseSettings = builtins.fromJSON (builtins.readFile ../modules/agents/providers/claude/settings.json);
  fontPolicy = import ../modules/packages/font-policy.nix;
  localePolicy = import ../modules/system/locale-policy.nix;
  appsHm = builtins.readFile ../modules/packages/apps.hm.nix;
  nixConfigHm = builtins.readFile ../modules/shell/nix-config.hm.nix;
  localeHm = builtins.readFile ../modules/system/locale.hm.nix;
  weztermHm = builtins.readFile ../modules/packages/wezterm.hm.nix;
  weztermTemplate = builtins.readFile ../dotfiles/wezterm/wezterm.lua;
  agentOpsEventShell = import ../modules/agents/runtime/agentops-event.nix {
    inherit lib;
    telemetry = {
      enabled = true;
      schemaVersion = "agentops.event.v1";
      otlp.enabled = false;
    };
    provider = "test";
  };
  collectOverlays = import ../lib/collect-overlays.nix {inherit lib;};
  discoverModules = import ../lib/discover-modules.nix {inherit lib;};
  agentPolicyEval = lib.evalModules {
    modules = [
      ({lib, ...}: {
        options.programs.mcp.servers = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = {};
        };
        options.agentPolicy._providerRuntime = lib.mkOption {
          type = lib.types.attrs;
          default = {};
        };
        options.assertions = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = [];
        };
      })
      ../modules/agents/policy-contract.nix
      ../modules/agents/policy-agentops-registry.nix
      ../modules/agents/policy-assertions.nix
      {
        programs.mcp.servers = {
          context7 = {};
          playwright = {};
        };
        agentPolicy.providers = {};
        agentPolicy._providerRuntime = {};
      }
    ];
  };

  # --- Assertion helper ---
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  # =========================================================================
  # 1. Overlay discovery (*.overlay.nix convention)
  # =========================================================================
  overlayTests = let
    collected = collectOverlays ../modules;
    appsOverlay = builtins.readFile ../modules/packages/apps.overlay.nix;
    fontsOverlay = builtins.readFile ../modules/packages/fonts.overlay.nix;
  in [
    (assert' "overlays: finds overlay files" (builtins.length collected > 0))
    (assert' "overlays: all are functions" (builtins.all builtins.isFunction collected))
    (assert' "overlays: expected count" (builtins.length collected == 3))
    (assert' "overlays: includes font package overlay" (
      builtins.pathExists ../modules/packages/fonts.overlay.nix
    ))
    (assert' "overlays: apps overlay does not own fonts" (!(lib.hasInfix "jetendard" appsOverlay)))
    (assert' "overlays: fonts overlay owns Jetendard package" (lib.hasInfix "jetendard" fontsOverlay))
  ];

  # =========================================================================
  # 2. Domain-module discovery (*.hm.nix / *.nixos.nix convention)
  # =========================================================================
  entrypointTests = let
    discovered = discoverModules ../modules;
  in [
    (assert' "discover: home-manager entrypoints is a list" (builtins.isList discovered.homeManager))
    (assert' "discover: 5+ home-manager entrypoints" (builtins.length discovered.homeManager >= 5))
    (assert' "discover: all hm end with .hm.nix" (
      builtins.all (p: lib.hasSuffix ".hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "discover: includes font SSoT module" (
      builtins.any (p: lib.hasSuffix "/modules/packages/fonts.hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "discover: includes locale Home Manager module" (
      builtins.any (p: lib.hasSuffix "/modules/system/locale.hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "discover: includes real shell Home Manager modules" (
      builtins.any (p: lib.hasSuffix "/modules/shell/fish.hm.nix" (toString p)) discovered.homeManager
      && builtins.any (p: lib.hasSuffix "/modules/shell/nix-config.hm.nix" (toString p)) discovered.homeManager
      && builtins.any (p: lib.hasSuffix "/modules/shell/zellij.hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "discover: does not keep synthetic shell entrypoints" (
      builtins.all (p:
        !(lib.hasSuffix "/modules/shell/shell.hm.nix" (toString p))
        && !(lib.hasSuffix "/modules/shell/shell-module.hm.nix" (toString p)))
      discovered.homeManager
    ))
    (assert' "discover: nixos entrypoints is a list" (builtins.isList discovered.nixos))
    (assert' "discover: 8+ nixos entrypoints" (builtins.length discovered.nixos >= 8))
    (assert' "discover: all nixos end with .nixos.nix" (
      builtins.all (p: lib.hasSuffix ".nixos.nix" (toString p)) discovered.nixos
    ))
  ];

  # =========================================================================
  # 3. Locale SSoT data integrity
  # =========================================================================
  localeTests = [
    (assert' "locale: LC_ALL is not a persistent policy variable" (!(localePolicy.homeSessionVariables ? LC_ALL)))
    (assert' "locale: default language is English UTF-8" (localePolicy.homeSessionVariables.LANG == "en_US.UTF-8"))
    (assert' "locale: Korean regional categories are explicit" (
      localePolicy.categoryLocales.LC_TIME
      == "ko_KR.UTF-8"
      && localePolicy.categoryLocales.LC_MONETARY == "ko_KR.UTF-8"
      && localePolicy.categoryLocales.LC_NUMERIC == "ko_KR.UTF-8"
    ))
    (assert' "locale: command-facing categories stay English" (
      localePolicy.categoryLocales.LC_COLLATE
      == "en_US.UTF-8"
      && localePolicy.categoryLocales.LC_CTYPE == "en_US.UTF-8"
      && localePolicy.categoryLocales.LC_MESSAGES == "en_US.UTF-8"
    ))
    (assert' "locale: Home Manager locale policy is owned by system module" (
      lib.hasInfix "locale-policy.nix" localeHm
      && !(lib.hasInfix "locale-policy.nix" nixConfigHm)
    ))
  ];

  # =========================================================================
  # 4. Font SSoT and WezTerm rendering boundary
  # =========================================================================
  fontTests = [
    (assert' "fonts: Jetendard family is centralized" (fontPolicy.jetendard.family == "Jetendard"))
    (assert' "fonts: WezTerm template does not hard-code managed font dirs" (
      !(lib.hasInfix ".local/share/fonts/Jetendard" weztermTemplate)
      && !(lib.hasInfix "Library/Fonts/Jetendard" weztermTemplate)
      && !(lib.hasInfix ".nix-profile/share/fonts" weztermTemplate)
    ))
    (assert' "fonts: apps module renders WezTerm config from font policy" (
      !(lib.hasInfix "font-policy.nix" appsHm)
      && lib.hasInfix "font-policy.nix" weztermHm
      && lib.hasInfix ".wezterm.lua\".text = weztermConfig" weztermHm
      && lib.hasInfix "fontPolicy.jetendard.family}," weztermHm
      && lib.hasInfix "-- @JETENDARD_FONT_DIRS@" weztermTemplate
      && lib.hasInfix "-- @JETENDARD_FAMILY@" weztermTemplate
    ))
  ];

  # =========================================================================
  # 5. MCP adapters (pure SSoT → per-provider shape)
  # =========================================================================
  mcpAdapterTests = let
    mockServers = {
      test-server = {
        command = "npx";
        args = ["-y" "test-mcp"];
        headers = {"X-Key" = "val";};
      };
    };
    adapted = mcpAdapt mockServers;
  in [
    (assert' "mcp-codex: has enabled flag" (adapted.codex.test-server.enabled == true))
    (assert' "mcp-codex: headers renamed to http_headers" (adapted.codex.test-server ? http_headers))
    (assert' "mcp-codex: original headers removed" (!(adapted.codex.test-server ? headers)))
    (assert' "mcp-gemini: only command+args" (adapted.gemini.test-server
      == {
        command = "npx";
        args = ["-y" "test-mcp"];
      }))
    (assert' "mcp-claude: pass-through" (adapted.claude == mockServers))
  ];

  # =========================================================================
  # 7. Hook adapters (policy SSoT -> per-provider native shape)
  # =========================================================================
  hookAdapterTests = let
    mockHooks = {
      path-guard = {
        claude = {
          event = "PreToolUse";
          matcher = "Read|Write";
          script = "/nix/store/path-guard-claude.sh";
        };
        codex = {
          event = "PreToolUse";
          matcher = "Read|Write";
          script = "/nix/store/path-guard-codex.sh";
        };
      };
      notify = {
        gemini = {
          event = "AfterAgent";
          matcher = "";
          script = "~/.claude/hooks/agent-notify.sh gemini";
        };
        codex = {
          event = "Stop";
          matcher = "";
          script = "~/.claude/hooks/agent-notify.sh codex";
        };
      };
    };
    claudeHooks = hookAdapt.claude mockHooks 5;
    geminiHooks = hookAdapt.gemini mockHooks 5;
    codexHooks = hookAdapt.codex mockHooks 5;
    hasClaudeAskNotifyHook =
      builtins.any (
        entry:
          (entry.matcher or "")
          == "AskUserQuestion"
          && builtins.any (
            hook:
              hook.type
              == "command"
              && hook.command == "~/.claude/hooks/agent-notify.sh claude"
              && hook.timeout == 5
          )
          (entry.hooks or [])
      )
      (claudeBaseSettings.hooks.PreToolUse or []);
  in [
    (assert' "hooks-claude: groups by event" (claudeHooks ? PreToolUse))
    (assert' "hooks-claude: preserves matcher wrapper" ((builtins.head claudeHooks.PreToolUse).matcher == "Read|Write"))
    (assert' "hooks-claude: command hook shape" ((builtins.head (builtins.head claudeHooks.PreToolUse).hooks).type == "command"))
    (assert' "hooks-claude: notifies when AskUserQuestion waits for user input" hasClaudeAskNotifyHook)
    (assert' "hooks-gemini: native event wrapper has hooks only" (
      (geminiHooks ? AfterAgent)
      && ((builtins.head geminiHooks.AfterAgent) ? hooks)
      && !((builtins.head geminiHooks.AfterAgent) ? matcher)
    ))
    (assert' "hooks-codex: supports PreToolUse and Stop" ((codexHooks ? PreToolUse) && (codexHooks ? Stop)))
    (assert' "hooks-codex: preserves matcher wrapper" ((builtins.head codexHooks.PreToolUse).matcher == "Read|Write"))
    (assert' "hooks-codex: command timeout is seconds" ((builtins.head (builtins.head codexHooks.Stop).hooks).timeout == 5))
  ];

  # =========================================================================
  # 8. Codex bindings (shared guide -> Codex skills/agents/permissions)
  # =========================================================================
  codexBindingTests = let
    roleNames = builtins.attrNames codexBindings.roles;
    commandWorkflowNames = builtins.attrNames workflowBindings.commandWorkflows;
    sampleSettings = codexBindings.mkSettings {
      hooks = {Stop = [];};
      mcp = {test-server = {enabled = true;};};
    };
    profileNames = builtins.attrNames codexBindings.permissionProfiles;
  in [
    (assert' "codex-bindings: exposes seven standard roles" (builtins.length roleNames == 7))
    (assert' "codex-bindings: each role has a matching agent skill" (
      builtins.all (name: builtins.hasAttr "agent-${name}" codexBindings.skills) roleNames
    ))
    (assert' "workflow-bindings: promotes Claude commands to provider-neutral workflows" (
      builtins.elem "commit" commandWorkflowNames
      && builtins.elem "create-pull-request" commandWorkflowNames
      && builtins.elem "evidence-debug" commandWorkflowNames
      && workflowBindings.commandWorkflows.commit.claudeCommand == "/commit"
    ))
    (assert' "workflow-bindings: exposes command workflows as Codex skills" (
      builtins.hasAttr "workflow-commit" codexBindings.skills
      && builtins.hasAttr "workflow-evidence-debug" codexBindings.skills
      && lib.hasInfix "Source Claude command: `/commit`" codexBindings.skills.workflow-commit
      && lib.hasInfix "PR 리뷰가 쉽도록 변경사항을 파일 변화 단위로 분석하고 커밋한다" codexBindings.skills.workflow-commit
      && lib.hasInfix "Source Claude command: `/evidence-debug`" codexBindings.skills.workflow-evidence-debug
      && lib.hasInfix "Prove a causal chain" codexBindings.skills.workflow-evidence-debug
    ))
    (assert' "codex-bindings: exposes A2A from modules/agents SSoT" (
      builtins.hasAttr "a2a-workflow" codexBindings.skills
      && !(builtins.pathExists ../.agents/skills/a2a-workflow/SKILL.md)
      && builtins.pathExists ../modules/agents/skills/a2a-workflow/SKILL.md
      && lib.hasInfix "name: a2a-workflow" (builtins.readFile ../modules/agents/skills/a2a-workflow/SKILL.md)
      && lib.hasInfix "Generated Reference Bundle" codexBindings.skills.a2a-workflow
      && lib.hasInfix "### references/routing.md" codexBindings.skills.a2a-workflow
      && lib.hasInfix "Repository writes have one owner" codexBindings.skills.a2a-workflow
    ))
    (assert' "workflow-bindings: renders shared CLI guide for non-Codex providers" (
      lib.hasInfix "## workflow-commit" workflowBindings.sharedGuide
      && lib.hasInfix "## workflow-evidence-debug" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Claude: `/commit" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Codex: invoke the `workflow-commit` skill" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Codex: invoke the `workflow-evidence-debug` skill" workflowBindings.sharedGuide
    ))
    (assert' "codex-bindings: each role points to an existing permission profile" (
      builtins.all (
        name: builtins.elem codexBindings.roles.${name}.permissionProfile profileNames
      )
      roleNames
    ))
    (assert' "codex-bindings: custom agents use standalone schema" (
      builtins.all (
        name:
          codexBindings.customAgents.${name}.name
          == name
          && codexBindings.customAgents.${name}.description == codexBindings.roles.${name}.description
          && builtins.isString codexBindings.customAgents.${name}.developer_instructions
          && codexBindings.customAgents.${name}.model == "gpt-5.5"
          && !(codexBindings.customAgents.${name} ? config_file)
      )
      roleNames
    ))
    (assert' "codex-bindings: reviewer is read-only" (
      codexBindings.permissionProfiles.agent-reviewer.filesystem.":workspace_roots"."." == "read"
    ))
    (assert' "codex-bindings: implementer can write workspace" (
      codexBindings.permissionProfiles.agent-implementer.filesystem.":workspace_roots"."." == "write"
    ))
    (assert' "codex-bindings: researcher has limited network enabled" (
      codexBindings.permissionProfiles.agent-researcher.network.enabled
      == true
      && codexBindings.permissionProfiles.agent-researcher.network.mode == "limited"
    ))
    (assert' "codex-bindings: context maps reviewer to Codex skill and permission profile" (
      lib.hasInfix "`reviewer` -> `agent-reviewer` / permission profile `agent-reviewer`" (codexBindings.mkContext "shared guide")
    ))
    (assert' "codex-settings: outports hooks and mcp_servers to Codex TOML shape" (
      sampleSettings.hooks
      == {Stop = [];}
      && sampleSettings.mcp_servers.test-server.enabled == true
      && sampleSettings.default_permissions == "default"
      && !(sampleSettings ? agents)
    ))
    (assert' "codex-bindings: stays focused on provider bridge data" (!(sampleSettings ? tui)))
  ];

  # =========================================================================
  # 9. AgentOps registry invariants
  # =========================================================================
  agentOpsRegistryTests = let
    policy = agentPolicyEval.config.agentPolicy;
    inherit (policy) registry;
    inherit (registry) capabilities;
    capabilityNames = builtins.attrNames capabilities;
    executorNames = builtins.attrNames registry.executors;
    workflowNames = builtins.attrNames registry.workflows;
    contextSourceNames = builtins.attrNames registry.repository.contextSources;
    assertions = agentPolicyEval.config.assertions;
    executorsFor = capability:
      builtins.filter (executor: builtins.elem capability registry.executors.${executor}.capabilities) executorNames;
  in [
    (assert' "agentops-registry: has standard capabilities" (
      builtins.all (capability: builtins.elem capability capabilityNames) [
        "planner"
        "researcher"
        "guardrail-designer"
        "implementer"
        "tester"
        "reviewer"
        "cross-validator"
        "postmortem-writer"
      ]
    ))
    (assert' "agentops-registry: every workflow capability is bound" (
      builtins.all (
        workflow:
          builtins.all (
            capability: executorsFor capability != []
          )
          registry.workflows.${workflow}.requiredCapabilities
      )
      workflowNames
    ))
    (assert' "agentops-registry: read-only capabilities bind only read executors" (
      builtins.all (
        capability: let
          cap = registry.capabilities.${capability};
        in
          !cap.readOnly
          || builtins.all (executor: registry.executors.${executor}.permission == "read") (executorsFor capability)
      )
      capabilityNames
    ))
    (assert' "agentops-registry: mutating workflows require evidence gates" (
      builtins.all (
        workflow: let
          w = registry.workflows.${workflow};
        in
          w.mutability
          != "mutating"
          || (
            w.verifyCommand
            != null
            && w.reviewRequired
            && w.postmortemRequired
            && builtins.elem "verify-command" w.requiredEvidence
            && builtins.elem "review-result" w.requiredEvidence
            && builtins.elem "postmortem-or-skip" w.requiredEvidence
          )
      )
      workflowNames
    ))
    (assert' "agentops-registry: mutating workflows declare phase graph" (
      builtins.all (
        workflow: let
          w = registry.workflows.${workflow};
        in
          w.mutability != "mutating" || w.phases != {}
      )
      workflowNames
    ))
    (assert' "agentops-registry: phase graph drives standard workflow loop" (
      let
        phases = registry.workflows.code-implementation.phases;
        implEntry = builtins.head phases.impl.entry;
        commitEntry = phases.commit.entry;
      in
        phases.guardrail-create.mutationAllowed
        && !phases.verify.mutationAllowed
        && builtins.elem {
          phase = "guardrail-verify";
          result = "pass";
        }
        implEntry
        && builtins.elem [
          {
            phase = "review";
            result = "pass";
          }
        ]
        commitEntry
    ))
    (assert' "agentops-registry: high-risk workflows have validation gate" (
      builtins.all (
        workflow: let
          w = registry.workflows.${workflow};
        in
          !(builtins.elem w.risk ["high" "destructive"]) || w.crossValidation || w.humanApproval
      )
      workflowNames
    ))
    (assert' "agentops-registry: workflow context references exist" (
      builtins.all (
        workflow:
          builtins.all (source: builtins.elem source contextSourceNames)
          registry.workflows.${workflow}.mandatoryContext
      )
      workflowNames
    ))
    (assert' "agentops-registry: MCP metadata covers declared servers" (
      builtins.hasAttr "context7" policy.tools.mcp
      && builtins.hasAttr "playwright" policy.tools.mcp
      && policy.tools.mcp.context7.network
      && policy.tools.mcp.playwright.write
    ))
    (assert' "agentops-registry: all module assertions pass in fixture" (
      builtins.all (entry: entry.assertion) assertions
    ))
  ];

  # =========================================================================
  # 10. AgentOps event helper contract
  # =========================================================================
  agentOpsEventTests = [
    (assert' "agentops-event: emits schema-required fields" (
      lib.hasInfix "schemaVersion: $schemaVersion" agentOpsEventShell
      && lib.hasInfix "event_id: $event_id" agentOpsEventShell
      && lib.hasInfix "run_id: $run_id" agentOpsEventShell
      && lib.hasInfix "event_type: $event_type" agentOpsEventShell
      && lib.hasInfix "content_capture: false" agentOpsEventShell
    ))
    (assert' "agentops-event: preserves telemetry compatibility fields" (
      lib.hasInfix "schema_version: $schema_version" agentOpsEventShell
      && lib.hasInfix "workflow_id: $workflow_id" agentOpsEventShell
      && lib.hasInfix "failure_taxonomy: $failure_taxonomy" agentOpsEventShell
      && lib.hasInfix "evidence_path: $evidence_path" agentOpsEventShell
    ))
  ];

  # =========================================================================
  allTests =
    overlayTests
    ++ entrypointTests
    ++ localeTests
    ++ fontTests
    ++ mcpAdapterTests
    ++ hookAdapterTests
    ++ codexBindingTests
    ++ agentOpsRegistryTests
    ++ agentOpsEventTests;
in {
  results = allTests;
  summary = {
    total = builtins.length allTests;
    passed = builtins.length (builtins.filter (t: t.pass) allTests);
  };
}
