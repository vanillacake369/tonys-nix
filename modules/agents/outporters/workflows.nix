# Provider-neutral workflow prompts rendered from Claude command sources.
{lib}: let
  commandDir = ../providers/claude/commands;
  join = lib.concatStringsSep;

  mkWorkflow = {
    name,
    file,
    description,
    role,
    mutatesFiles ? false,
    needsNetwork ? false,
    needsMcp ? [],
    argumentHint ? "task context",
  }: let
    body = builtins.readFile (commandDir + "/${file}");
    skillName = "workflow-${name}";
  in {
    inherit name file description role mutatesFiles needsNetwork needsMcp argumentHint body skillName;
    claudeCommand = "/${lib.removeSuffix ".md" file}";
  };

  commandWorkflows = {
    commit = mkWorkflow {
      name = "commit";
      file = "commit.md";
      description = "PR 리뷰가 쉽도록 변경사항을 파일 변화 단위로 분석하고 커밋한다";
      role = "implementer";
      mutatesFiles = true;
      argumentHint = "commit scope or constraints";
    };
    create-pull-request = mkWorkflow {
      name = "create-pull-request";
      file = "create-pull-request.md";
      description = "현재 브랜치의 변경사항을 분석하여 PR을 생성한다";
      role = "implementer";
      needsNetwork = true;
      argumentHint = "PR context, reviewers, or discussion points";
    };
    code-enhance = mkWorkflow {
      name = "code-enhance";
      file = "code-enhance.md";
      description = "코드 품질, 성능, 보안을 분석하고 개선한다";
      role = "implementer";
      mutatesFiles = true;
      argumentHint = "target files, modules, or quality concern";
    };
    debug-system = mkWorkflow {
      name = "debug-system";
      file = "debug-system.md";
      description = "Orchestrate skills to systematically debug issues with root cause analysis";
      role = "tester";
      mutatesFiles = true;
      argumentHint = "bug report, failure log, or reproduction steps";
    };
    evidence-debug = mkWorkflow {
      name = "evidence-debug";
      file = "evidence-debug.md";
      description = "Evidence-first debugging workflow for repeated hook/runtime failures, policy or guardrail regressions, stale state/config problems, and explicit preferred review loops";
      role = "tester";
      mutatesFiles = true;
      argumentHint = "hook failure, stale state, guardrail regression, or repeated debug failure";
    };
    scaffold = mkWorkflow {
      name = "scaffold";
      file = "scaffold.md";
      description = "Scaffold a new project or feature from a concise implementation target";
      role = "implementer";
      mutatesFiles = true;
      argumentHint = "project or feature to scaffold";
    };
    blog-korean = mkWorkflow {
      name = "blog-korean";
      file = "blog-korean.md";
      description = "한국어 기술 블로그 초안을 작성한다";
      role = "implementer";
      mutatesFiles = true;
      needsMcp = ["context7"];
      argumentHint = "topic, source material, and target audience";
    };
    blog-refine = mkWorkflow {
      name = "blog-refine";
      file = "blog-refine.md";
      description = "한국어 기술 블로그 초안을 다듬는다";
      role = "implementer";
      mutatesFiles = true;
      needsMcp = ["context7"];
      argumentHint = "draft path or refinement goal";
    };
    test-doc-korean = mkWorkflow {
      name = "test-doc-korean";
      file = "test-doc-korean.md";
      description = "테스트 문서를 한국어로 작성한다";
      role = "tester";
      mutatesFiles = true;
      argumentHint = "test target, source files, or documentation scope";
    };
    todo-task-management = mkWorkflow {
      name = "todo-task-management";
      file = "todo-task-management.md";
      description = "외부 todo MCP 서버를 통해 task를 조회하고 안전하게 관리한다";
      role = "implementer";
      needsNetwork = true;
      needsMcp = ["ticktick"];
      argumentHint = "todo query, task change request, or planning context";
    };
  };

  renderNeeds = workflow:
    join ", " (
      (lib.optional workflow.mutatesFiles "workspace-write")
      ++ (lib.optional workflow.needsNetwork "network")
      ++ (map (name: "mcp:${name}") workflow.needsMcp)
    );

  renderCodexSkill = workflow: ''
    ---
    name: ${workflow.skillName}
    description: ${workflow.description}
    ---

    # ${workflow.skillName}

    Use this Codex skill when the user asks for the provider-neutral workflow
    `${workflow.name}` or the Claude slash command `${workflow.claudeCommand}`.

    Source Claude command: `${workflow.claudeCommand}`
    Recommended role: `${workflow.role}`
    Argument hint: ${workflow.argumentHint}
    Required capabilities: ${
      if renderNeeds workflow == ""
      then "none beyond the active session permissions"
      else renderNeeds workflow
    }

    If the source prompt refers to `$ARGUMENTS`, treat the current user request
    and any explicit context as that argument value. Claude-only command syntax
    is provenance, not a requirement to call Claude-specific tools.

    ## Source Prompt

    ${workflow.body}
  '';

  codexSkills =
    lib.mapAttrs' (_: workflow: {
      name = workflow.skillName;
      value = renderCodexSkill workflow;
    })
    commandWorkflows;

  sharedGuide = ''
    # Shared Agent Workflows

    These workflows are provider-neutral bindings for curated prompts that are
    currently stored as Claude slash commands.

    ${join "\n\n" (lib.mapAttrsToList (_: workflow: ''
        ## ${workflow.skillName}

        ${workflow.description}

        - Role: `${workflow.role}`
        - Use from Claude: `${workflow.claudeCommand} ${workflow.argumentHint}`
        - Use from Codex: invoke the `${workflow.skillName}` skill
        - Use from Gemini/agy: ask for `${workflow.name}` and follow this workflow guide
      '')
      commandWorkflows)}
  '';
in {
  inherit commandWorkflows codexSkills sharedGuide;
}
