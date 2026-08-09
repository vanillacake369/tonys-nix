{lib}: let
  workflowBindings = import ../outporters/workflows.nix {inherit lib;};
in rec {
  sharedGuidePath = ./shared/AGENTS.md;
  sharedGuide = builtins.readFile sharedGuidePath;

  codexModel = "gpt-5.5";
  codexTui = {
    status_line = [
      "model-with-reasoning"
      "current-dir"
      "git-branch"
      "permissions"
      "five-hour-limit"
      "weekly-limit"
      "task-progress"
    ];
    status_line_use_colors = true;
  };

  providerHooks = {
    codex = {
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "~/.claude/hooks/agent-notify.sh codex";
              timeout = 5;
            }
          ];
        }
      ];
    };

    gemini = {
      AfterAgent = [
        {
          hooks = [
            {
              type = "command";
              command = "~/.claude/hooks/agent-notify.sh gemini";
              timeout = 5000;
            }
          ];
        }
      ];
    };
  };

  workflows = workflowBindings;
}
