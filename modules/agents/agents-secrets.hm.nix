# Runtime secret environment for agent launchers.
{pkgs, ...}: let
  agentSecretEnv = pkgs.writeShellApplication {
    name = "agent-secret-env";
    runtimeInputs = [pkgs.sops];
    text = ''
      if [ "$#" -eq 0 ]; then
        echo "usage: agent-secret-env <command> [args...]" >&2
        exit 64
      fi

      secrets_file="''${AGENT_SECRETS_FILE:-$HOME/dev/tonys-nix/secrets/secrets.yaml}"

      if [ -z "''${TICKTICK_MCP_TOKEN:-}" ] && [ -f "$secrets_file" ]; then
        token="$(sops --decrypt --extract '["ticktick"]["mcp_token"]' "$secrets_file" 2>/dev/null || true)"
        if [ -n "$token" ] && [ "$token" != "null" ]; then
          export TICKTICK_MCP_TOKEN="$token"
        fi
      fi

      exec "$@"
    '';
  };
in {
  home.packages = [agentSecretEnv];
}
