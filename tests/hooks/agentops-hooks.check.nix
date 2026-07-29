{
  pkgs,
  homeConfig,
  ...
}: let
  workflowGatePreHook = homeConfig.config.agentPolicy._hooks.workflow-gate-pre.claude.script;
  workflowGatePostHook = homeConfig.config.agentPolicy._hooks.workflow-gate-post.claude.script;
  pathGuardHook = homeConfig.config.agentPolicy._hooks.path-guard.claude.script;
  codexHasWorkflowGate =
    ((homeConfig.config.agentPolicy._hooks.workflow-gate-pre or {}) ? codex)
    || ((homeConfig.config.agentPolicy._hooks.workflow-gate-post or {}) ? codex);
  codexPathGuardHook = homeConfig.config.agentPolicy._hooks.path-guard.codex.script;
  reasoningTraceHook = homeConfig.config.agentPolicy._hooks.reasoning-trace.claude.script;
  codexReasoningTraceHook = homeConfig.config.agentPolicy._hooks.reasoning-trace.codex.script;
  asyncHandshakeHook = homeConfig.config.agentPolicy._hooks.async-handshake.gemini.script;
in {
  agentops-workflow-gate-hooks =
    pkgs.runCommand "agentops-workflow-gate-hooks" {
      nativeBuildInputs = [
        pkgs.bash
        pkgs.bats
        pkgs.jq
      ];
    } ''
      set -euo pipefail
      # This fixture needs generated hook script paths, so it is intentionally
      # run only through this flake check and skipped by direct `just test-hooks`.
      export PRE_HOOK="${workflowGatePreHook}"
      export POST_HOOK="${workflowGatePostHook}"
      bats ${./agentops-workflow-gate.bats}
      export PATH_GUARD_HOOK="${pathGuardHook}"
      bats ${./path-guard.bats}
      test "${
        if codexHasWorkflowGate
        then "true"
        else "false"
      }" = "false"
      export PATH_GUARD_HOOK="${codexPathGuardHook}"
      bats ${./path-guard.bats}
      export REASONING_TRACE_HOOK="${reasoningTraceHook}"
      export CODEX_REASONING_TRACE_HOOK="${codexReasoningTraceHook}"
      export ASYNC_HANDSHAKE_HOOK="${asyncHandshakeHook}"
      bats ${./generated-posttool-payload.bats}
      touch "$out"
    '';
}
