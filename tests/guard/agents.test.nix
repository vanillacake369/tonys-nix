{lib}: let
  mcpRender = import ../../modules/agents/outporters/mcp.nix {inherit lib;};
  workflowBindings = import ../../modules/agents/outporters/workflows.nix {inherit lib;};
  agentSource = import ../../modules/agents/source-of-truth {inherit lib;};
  codexBindings = import ../../modules/agents/providers/codex/bindings.nix {inherit lib;};
  claudeBaseSettings = builtins.fromJSON (builtins.readFile ../../modules/agents/providers/claude/settings.json);

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  mockServers = {
    test-server = {
      command = "npx";
      args = ["-y" "test-mcp"];
      url = null;
      headers = {"X-Key" = "val";};
    };
    remote-server = {
      url = "https://mcp.example.test";
      transport = "streamable-http";
      args = [];
      headers = {"X-Key" = "val";};
      bearerTokenEnvVar = "EXAMPLE_MCP_TOKEN";
    };
  };
  rendered = mcpRender mockServers;
  sourceText = builtins.readFile ../../modules/agents/source-of-truth/default.nix;
  moduleText = builtins.readFile ../../modules/agents/agents-module.hm.nix;
  roleNames = builtins.attrNames codexBindings.roles;
  commandWorkflowNames = builtins.attrNames workflowBindings.commandWorkflows;
  sampleSettings = codexBindings.mkSettings {
    hooks = agentSource.providerHooks.codex;
    mcp = {test-server = {enabled = true;};};
  };
  profileNames = builtins.attrNames codexBindings.permissionProfiles;
in {
  results = [
    (assert' "GIVEN MCP source WHEN rendering Codex stdio server THEN enabled flag is present" (rendered.codex.test-server.enabled == true))
    (assert' "GIVEN MCP source WHEN rendering Codex stdio server THEN command args are preserved" (
      rendered.codex.test-server.command
      == "npx"
      && rendered.codex.test-server.args == ["-y" "test-mcp"]
      && !(rendered.codex.test-server ? url)
    ))
    (assert' "GIVEN MCP source WHEN rendering Codex server THEN headers are renamed to http_headers" (rendered.codex.test-server ? http_headers))
    (assert' "GIVEN MCP source WHEN rendering Codex server THEN original headers are removed" (!(rendered.codex.test-server ? headers)))
    (assert' "GIVEN MCP source WHEN rendering Codex remote server THEN bearer token uses env var" (
      rendered.codex.remote-server.url
      == "https://mcp.example.test"
      && rendered.codex.remote-server.http_headers.X-Key == "val"
      && rendered.codex.remote-server.bearer_token_env_var == "EXAMPLE_MCP_TOKEN"
      && !(rendered.codex.remote-server ? args)
      && !(rendered.codex.remote-server ? bearerTokenEnvVar)
    ))
    (assert' "GIVEN MCP source WHEN rendering Gemini stdio server THEN only command and args remain" (rendered.gemini.test-server
      == {
        command = "npx";
        args = ["-y" "test-mcp"];
      }))
    (assert' "GIVEN MCP source WHEN rendering Gemini remote server THEN streamable HTTP uses httpUrl" (
      rendered.gemini.remote-server
      == {
        httpUrl = "https://mcp.example.test";
        headers = {"X-Key" = "val";};
      }
    ))
    (assert' "GIVEN MCP source WHEN rendering Claude stdio server THEN type is stdio" (
      rendered.claude.test-server.type
      == "stdio"
      && rendered.claude.test-server.command == "npx"
    ))
    (assert' "GIVEN MCP source WHEN rendering Claude remote server THEN type is http" (
      rendered.claude.remote-server
      == {
        headers = {"X-Key" = "val";};
        type = "http";
        url = "https://mcp.example.test";
      }
      && !(rendered.claude.remote-server ? args)
    ))
    (assert' "GIVEN agent source WHEN shared guide path is read THEN source owns shared guide" (agentSource.sharedGuidePath == ../../modules/agents/source-of-truth/shared/AGENTS.md))
    (assert' "GIVEN agent source WHEN Codex model is read THEN model is explicit" (agentSource.codexModel == "gpt-5.5"))
    (assert' "GIVEN provider hooks WHEN Codex stop hook is read THEN timeout uses seconds" (
      (builtins.head (builtins.head agentSource.providerHooks.codex.Stop).hooks).timeout == 5
    ))
    (assert' "GIVEN provider hooks WHEN Gemini after-agent hook is read THEN timeout uses milliseconds" (
      (builtins.head (builtins.head agentSource.providerHooks.gemini.AfterAgent).hooks).timeout == 5000
    ))
    (assert' "GIVEN agent module WHEN provider exporters are wired THEN all providers are imported directly" (
      lib.hasInfix "./providers/claude/module.nix" moduleText
      && lib.hasInfix "./providers/codex/module.nix" moduleText
      && lib.hasInfix "./providers/gemini/module.nix" moduleText
    ))
    (assert' "GIVEN agent source WHEN source text is checked THEN shared exporter data stays focused" (
      lib.hasInfix "providerHooks" sourceText
      && lib.hasInfix "workflows" sourceText
    ))
    (assert' "GIVEN Codex bindings WHEN roles are exported THEN seven standard roles exist" (builtins.length roleNames == 7))
    (assert' "GIVEN Codex bindings WHEN roles are exported THEN each role has a matching skill" (
      builtins.all (name: builtins.hasAttr "agent-${name}" codexBindings.skills) roleNames
    ))
    (assert' "GIVEN workflow bindings WHEN command workflows are promoted THEN expected workflows exist" (
      builtins.elem "commit" commandWorkflowNames
      && builtins.elem "create-pull-request" commandWorkflowNames
      && builtins.elem "evidence-debug" commandWorkflowNames
      && builtins.elem "todo-task-management" commandWorkflowNames
      && workflowBindings.commandWorkflows.commit.claudeCommand == "/commit"
    ))
    (assert' "GIVEN workflow bindings WHEN Codex skills are rendered THEN command aliases are preserved" (
      builtins.hasAttr "workflow-commit" codexBindings.skills
      && builtins.hasAttr "workflow-evidence-debug" codexBindings.skills
      && builtins.hasAttr "workflow-todo-task-management" codexBindings.skills
      && lib.hasInfix "Claude command alias: `/commit`" codexBindings.skills.workflow-commit
      && lib.hasInfix "Claude command alias: `/evidence-debug`" codexBindings.skills.workflow-evidence-debug
    ))
    (assert' "GIVEN Codex bindings WHEN A2A skill is exported THEN source-of-truth workflow is bundled" (
      builtins.hasAttr "a2a-workflow" codexBindings.skills
      && builtins.pathExists ../../modules/agents/source-of-truth/skills/a2a-workflow/SKILL.md
      && lib.hasInfix "name: a2a-workflow" (builtins.readFile ../../modules/agents/source-of-truth/skills/a2a-workflow/SKILL.md)
      && lib.hasInfix "Generated Reference Bundle" codexBindings.skills.a2a-workflow
    ))
    (assert' "GIVEN workflow bindings WHEN shared guide is rendered THEN provider usage hints are present" (
      lib.hasInfix "## workflow-commit" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Claude: `/commit" workflowBindings.sharedGuide
      && lib.hasInfix "Use from Codex: invoke the `workflow-commit` skill" workflowBindings.sharedGuide
    ))
    (assert' "GIVEN Codex bindings WHEN roles are exported THEN each role points to a permission profile" (
      builtins.all (
        name: builtins.elem codexBindings.roles.${name}.permissionProfile profileNames
      )
      roleNames
    ))
    (assert' "GIVEN Codex bindings WHEN custom agents are rendered THEN standalone schema is used" (
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
    (assert' "GIVEN Codex permission profiles WHEN reviewer is exported THEN reviewer is read-only" (
      codexBindings.permissionProfiles.agent-reviewer.filesystem.":workspace_roots"."." == "read"
    ))
    (assert' "GIVEN Codex permission profiles WHEN implementer is exported THEN implementer can write workspace" (
      codexBindings.permissionProfiles.agent-implementer.filesystem.":workspace_roots"."." == "write"
    ))
    (assert' "GIVEN Codex permission profiles WHEN researcher is exported THEN limited network is enabled" (
      codexBindings.permissionProfiles.agent-researcher.network.enabled
      == true
      && codexBindings.permissionProfiles.agent-researcher.network.mode == "limited"
    ))
    (assert' "GIVEN Codex context WHEN reviewer mapping is rendered THEN skill and permission profile are shown" (
      lib.hasInfix "`reviewer` -> `agent-reviewer` / permission profile `agent-reviewer`" (codexBindings.mkContext "shared guide")
    ))
    (assert' "GIVEN Codex settings WHEN hooks and MCP are rendered THEN TOML shape data is exported" (
      sampleSettings.hooks
      == agentSource.providerHooks.codex
      && sampleSettings.mcp_servers.test-server.enabled == true
      && sampleSettings.default_permissions == "default"
      && !(sampleSettings ? agents)
    ))
    (assert' "GIVEN Codex bindings WHEN settings are rendered THEN provider bridge data stays focused" (!(sampleSettings ? tui)))
    (assert' "GIVEN Claude settings WHEN static hooks are loaded THEN native hook groups remain present" (
      claudeBaseSettings.hooks ? UserPromptSubmit
      && claudeBaseSettings.hooks ? PreToolUse
      && claudeBaseSettings.hooks ? PostToolUse
      && claudeBaseSettings.hooks ? Stop
    ))
    (assert' "GIVEN Claude settings WHEN AskUserQuestion waits for input THEN notification hook is configured" (
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
}
