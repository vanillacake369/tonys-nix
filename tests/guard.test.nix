# Guard tests: core invariants only (discovery, SSoT data, pure outporters).
# Run: nix build --print-out-paths .#checks.<system>.guard-tests --no-link
{lib}: let
  mcpRender = import ../modules/agents/outporters/mcp.nix {inherit lib;};
  workflowBindings = import ../modules/agents/outporters/workflows.nix {inherit lib;};
  agentSource = import ../modules/agents/source-of-truth {inherit lib;};
  codexBindings = import ../modules/agents/providers/codex/bindings.nix {inherit lib;};
  claudeBaseSettings = builtins.fromJSON (builtins.readFile ../modules/agents/providers/claude/settings.json);
  fontPolicy = import ../modules/packages/font-policy.nix;
  localePolicy = import ../modules/system/locale-policy.nix;
  appsHm = builtins.readFile ../modules/packages/apps.hm.nix;
  nixConfigHm = builtins.readFile ../modules/shell/nix-config.hm.nix;
  localeHm = builtins.readFile ../modules/system/locale.hm.nix;
  weztermHm = builtins.readFile ../modules/packages/wezterm.hm.nix;
  weztermTemplate = builtins.readFile ../dotfiles/wezterm/wezterm.lua;
  collectOverlays = import ../lib/collect-overlays.nix {inherit lib;};
  discoverModules = import ../lib/discover-modules.nix {inherit lib;};

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  overlayTests = let
    collected = collectOverlays ../modules;
    appsOverlay = builtins.readFile ../modules/packages/apps.overlay.nix;
    fontsOverlay = builtins.readFile ../modules/packages/fonts.overlay.nix;
  in [
    (assert' "overlays: finds overlay files" (builtins.length collected > 0))
    (assert' "overlays: all are functions" (builtins.all builtins.isFunction collected))
    (assert' "overlays: expected count" (builtins.length collected == 3))
    (assert' "overlays: includes agent proxy bridge" (
      builtins.pathExists ../modules/agents/agents-proxy.overlay.nix
    ))
    (assert' "overlays: apps overlay does not own fonts" (!(lib.hasInfix "jetendard" appsOverlay)))
    (assert' "overlays: fonts overlay owns Jetendard package" (lib.hasInfix "jetendard" fontsOverlay))
  ];

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

  mcpRendererTests = let
    mockServers = {
      test-server = {
        command = "npx";
        args = ["-y" "test-mcp"];
        headers = {"X-Key" = "val";};
      };
    };
    rendered = mcpRender mockServers;
  in [
    (assert' "mcp-codex: has enabled flag" (rendered.codex.test-server.enabled == true))
    (assert' "mcp-codex: headers renamed to http_headers" (rendered.codex.test-server ? http_headers))
    (assert' "mcp-codex: original headers removed" (!(rendered.codex.test-server ? headers)))
    (assert' "mcp-gemini: only command+args" (rendered.gemini.test-server
      == {
        command = "npx";
        args = ["-y" "test-mcp"];
      }))
    (assert' "mcp-claude: pass-through" (rendered.claude == mockServers))
  ];

  agentExporterTests = let
    sourceText = builtins.readFile ../modules/agents/source-of-truth/default.nix;
    moduleText = builtins.readFile ../modules/agents/agents-module.hm.nix;
  in [
    (assert' "agents-source: owns shared guide path" (agentSource.sharedGuidePath == ../modules/agents/source-of-truth/shared/AGENTS.md))
    (assert' "agents-source: codex model is explicit" (agentSource.codexModel == "gpt-5.5"))
    (assert' "agents-source: codex hook timeout is seconds" (
      (builtins.head (builtins.head agentSource.providerHooks.codex.Stop).hooks).timeout == 5
    ))
    (assert' "agents-source: gemini hook timeout is milliseconds" (
      (builtins.head (builtins.head agentSource.providerHooks.gemini.AfterAgent).hooks).timeout == 5000
    ))
    (assert' "agents-module: imports provider exporters directly" (
      lib.hasInfix "./providers/claude/module.nix" moduleText
      && lib.hasInfix "./providers/codex/module.nix" moduleText
      && lib.hasInfix "./providers/gemini/module.nix" moduleText
    ))
    (assert' "agents-source: stays focused on shared exporter data" (
      lib.hasInfix "providerHooks" sourceText
      && lib.hasInfix "workflows" sourceText
    ))
  ];

  codexBindingTests = let
    roleNames = builtins.attrNames codexBindings.roles;
    commandWorkflowNames = builtins.attrNames workflowBindings.commandWorkflows;
    sampleSettings = codexBindings.mkSettings {
      hooks = agentSource.providerHooks.codex;
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
      && lib.hasInfix "Source Claude command: `/evidence-debug`" codexBindings.skills.workflow-evidence-debug
    ))
    (assert' "codex-bindings: exposes A2A from modules/agents SSoT" (
      builtins.hasAttr "a2a-workflow" codexBindings.skills
      && builtins.pathExists ../modules/agents/source-of-truth/skills/a2a-workflow/SKILL.md
      && lib.hasInfix "name: a2a-workflow" (builtins.readFile ../modules/agents/source-of-truth/skills/a2a-workflow/SKILL.md)
      && lib.hasInfix "Generated Reference Bundle" codexBindings.skills.a2a-workflow
    ))
    (assert' "workflow-bindings: renders shared CLI guide for non-Codex providers" (
      lib.hasInfix "## workflow-commit" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Claude: `/commit" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Codex: invoke the `workflow-commit` skill" workflowBindings.sharedGuide
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
      == agentSource.providerHooks.codex
      && sampleSettings.mcp_servers.test-server.enabled == true
      && sampleSettings.default_permissions == "default"
      && !(sampleSettings ? agents)
    ))
    (assert' "codex-bindings: stays focused on provider bridge data" (!(sampleSettings ? tui)))
  ];

  claudeSettingsTests = [
    (assert' "claude-settings: keeps static native hooks" (
      claudeBaseSettings.hooks ? UserPromptSubmit
      && claudeBaseSettings.hooks ? PreToolUse
      && claudeBaseSettings.hooks ? PostToolUse
      && claudeBaseSettings.hooks ? Stop
    ))
    (assert' "claude-settings: notifies when AskUserQuestion waits for input" (
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
      (claudeBaseSettings.hooks.PreToolUse or [])
    ))
  ];

  allTests =
    overlayTests
    ++ entrypointTests
    ++ localeTests
    ++ fontTests
    ++ mcpRendererTests
    ++ agentExporterTests
    ++ codexBindingTests
    ++ claudeSettingsTests;
in {
  results = allTests;
  summary = {
    total = builtins.length allTests;
    passed = builtins.length (builtins.filter (t: t.pass) allTests);
  };
}
