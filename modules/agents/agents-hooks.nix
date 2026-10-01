# Provider-neutral hooks used by the active agent provider.
{
  home.file = {
    ".config/agents/hooks/agent-notify.sh".source = ./providers/claude/hooks/agent-notify.sh;
    ".config/agents/hooks/agent-notify-open.sh".source = ./providers/claude/hooks/agent-notify-open.sh;
  };
}
