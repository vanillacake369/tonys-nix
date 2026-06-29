# Guard tests: core invariants only (discovery, SSoT data, pure mappers).
# Detailed output-format / platform / policy-internal tests were intentionally
# dropped — build-time assertions + `nix flake check` + per-platform builds
# cover the rest. Keep this file small so the structure stays flexible.
# Run: nix build --print-out-paths .#checks.<system>.guard-tests --no-link
# Run verbose:
#   nix eval --impure --json --expr 'let flake = builtins.getFlake (toString ./.); collectTests = (import ./lib/collect-tests.nix { lib = flake.inputs.nixpkgs.lib; }) ./tests; in (collectTests { lib = flake.inputs.nixpkgs.lib; }).results'
{lib}: let
  # --- Fixtures ---
  userProfile = import ../user/limjihoon.nix;
  keybinds = import ../modules/keymap/binds.nix {inherit lib userProfile;};
  mcpAdapt = import ../modules/agents/mcp-adapters.nix {inherit lib;};
  hookAdapt = import ../modules/agents/policy-hook-adapters.nix {inherit lib;};
  workflowBindings = import ../modules/agents/workflow-bindings.nix {inherit lib;};
  codexBindings = import ../modules/agents/codex-bindings.nix {inherit lib;};
  collectOverlays = import ../lib/collect-overlays.nix {inherit lib;};
  discoverModules = import ../lib/discover-modules.nix {inherit lib;};

  # --- Assertion helper ---
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else builtins.throw "FAIL: ${name}";

  # =========================================================================
  # 1. Overlay discovery (*.overlay.nix convention)
  # =========================================================================
  overlayTests = let
    collected = collectOverlays ../modules;
  in [
    (assert' "overlays: finds overlay files" (builtins.length collected > 0))
    (assert' "overlays: all are functions" (builtins.all builtins.isFunction collected))
    (assert' "overlays: expected count" (builtins.length collected == 3))
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
    (assert' "discover: nixos entrypoints is a list" (builtins.isList discovered.nixos))
    (assert' "discover: 8+ nixos entrypoints" (builtins.length discovered.nixos >= 8))
    (assert' "discover: all nixos end with .nixos.nix" (
      builtins.all (p: lib.hasSuffix ".nixos.nix" (toString p)) discovered.nixos
    ))
  ];

  # =========================================================================
  # 3. Keymap SSoT data integrity
  # =========================================================================
  keymapTests = let
    karabinerMaps = builtins.filter (m: builtins.elem "karabiner" m.tags) keybinds.keymaps;
    aerospaceMaps = builtins.filter (m: builtins.elem "aerospace" m.tags) keybinds.keymaps;
  in [
    (assert' "keymaps: has entries" (builtins.length keybinds.keymaps > 0))
    (assert' "keymaps: karabiner maps" (builtins.length karabinerMaps > 0))
    (assert' "keymaps: aerospace maps" (builtins.length aerospaceMaps > 0))
    (assert' "keymaps: 6+ workspaces" (builtins.length (builtins.attrNames keybinds.workspaces) >= 6))
    (assert' "keymaps: workspaces declare monitors" (
      builtins.all (name: keybinds.workspaces.${name} ? monitor) (builtins.attrNames keybinds.workspaces)
    ))
    (assert' "keymaps: workspace app routes are lists when present" (
      builtins.all (
        name: let
          workspace = keybinds.workspaces.${name};
        in
          !(workspace ? apps) || builtins.isList workspace.apps
      ) (builtins.attrNames keybinds.workspaces)
    ))
  ];

  # =========================================================================
  # 4. MCP adapters (pure SSoT → per-provider shape)
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
  # 5. Hook adapters (policy SSoT -> per-provider native shape)
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
  in [
    (assert' "hooks-claude: groups by event" (claudeHooks ? PreToolUse))
    (assert' "hooks-claude: preserves matcher wrapper" ((builtins.head claudeHooks.PreToolUse).matcher == "Read|Write"))
    (assert' "hooks-claude: command hook shape" ((builtins.head (builtins.head claudeHooks.PreToolUse).hooks).type == "command"))
    (assert' "hooks-gemini: native event wrapper has hooks only" (
      (geminiHooks ? AfterAgent)
      && ((builtins.head geminiHooks.AfterAgent) ? hooks)
      && !((builtins.head geminiHooks.AfterAgent) ? matcher)
    ))
    (assert' "hooks-codex: supports PreToolUse and Stop" ((codexHooks ? PreToolUse) && (codexHooks ? Stop)))
    (assert' "hooks-codex: command timeout is seconds" ((builtins.head (builtins.head codexHooks.Stop).hooks).timeout == 5))
  ];

  # =========================================================================
  # 6. Codex bindings (shared guide -> Codex skills/agents/permissions)
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
      && workflowBindings.commandWorkflows.commit.claudeCommand == "/commit"
    ))
    (assert' "workflow-bindings: exposes command workflows as Codex skills" (
      builtins.hasAttr "workflow-commit" codexBindings.skills
      && lib.hasInfix "Source Claude command: `/commit`" codexBindings.skills.workflow-commit
      && lib.hasInfix "SRP 기준으로 변경사항을 분리하여 커밋한다" codexBindings.skills.workflow-commit
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
      == {Stop = [];}
      && sampleSettings.mcp_servers.test-server.enabled == true
      && sampleSettings.default_permissions == "default"
      && !(sampleSettings ? agents)
    ))
    (assert' "codex-bindings: stays focused on provider bridge data" (!(sampleSettings ? tui)))
  ];

  # =========================================================================
  # 7. Zellij config generation (platform-conditional)
  # =========================================================================
  zellijTests = let
    darwinConfig = import ../lib/mk-zellij-config.nix {isDarwin = true;};
    linuxConfig = import ../lib/mk-zellij-config.nix {isDarwin = false;};
  in [
    (assert' "zellij-darwin: pbcopy" (lib.hasInfix ''copy_command "pbcopy"'' darwinConfig))
    (assert' "zellij-darwin: kitty protocol" (lib.hasInfix "support_kitty_keyboard_protocol true" darwinConfig))
    (assert' "zellij-linux: xclip" (lib.hasInfix ''copy_command "xclip -selection clipboard"'' linuxConfig))
    (assert' "zellij-both: has keybinds" (lib.hasInfix "keybinds clear-defaults=true" darwinConfig))
  ];

  # =========================================================================
  allTests =
    overlayTests
    ++ entrypointTests
    ++ keymapTests
    ++ mcpAdapterTests
    ++ hookAdapterTests
    ++ codexBindingTests
    ++ zellijTests;
in {
  results = allTests;
  summary = {
    total = builtins.length allTests;
    passed = builtins.length (builtins.filter (t: t.pass) allTests);
  };
}
