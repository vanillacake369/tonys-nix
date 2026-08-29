{
  pkgs,
  homeConfig,
  ...
}: let
  codexSyncScript = homeConfig.config.home.activation.syncCodexConfig.data;
  codexAgentFiles = builtins.filter (entry: builtins.match "\\.codex/agents/.*\\.toml" entry.path != null) (
    builtins.attrValues (
      builtins.mapAttrs (path: file: {
        inherit path;
        inherit (file) source;
      })
      homeConfig.config.home.file
    )
  );
  agentFileChecks = builtins.concatStringsSep "\n" (
    map (entry: ''
      echo "[!] Checking custom agent file: ${entry.path}"
      grep -F 'name = ' '${entry.source}'
      grep -F 'description = ' '${entry.source}'
      grep -F 'developer_instructions = ' '${entry.source}'
      grep -F 'model = "gpt-5.5"' '${entry.source}'
      grep -F 'default_permissions = "agent-' '${entry.source}'
      ! grep -F 'config_file = ' '${entry.source}'
    '')
    codexAgentFiles
  );
in {
  codex-settings-sync = pkgs.runCommand "codex-settings-sync" {} ''
    set -euo pipefail
    export HOME="$PWD/home"
    mkdir -p "$HOME/.codex"

    cat > "$HOME/.codex/config.toml" <<'TOML'
    [tui]
    status_line = ["old"]
    status_line_use_colors = false

    [projects.demo]
    trusted = true

    [hooks.state."/tmp/stale:post_tool_use:0:1"]
    trusted_hash = "sha256:stale"
    TOML
    {
      echo
      echo "[hooks.state.\"$HOME/.codex/config.toml:post_tool_use:0:0\"]"
      echo 'trusted_hash = "sha256:valid"'
      echo
      echo "[hooks.state.\"$HOME/.codex/hooks.json:stop:0:0\"]"
      echo 'trusted_hash = "sha256:obsolete"'
    } >> "$HOME/.codex/config.toml"
    cat > "$HOME/.codex/hooks.json" <<'JSON'
    {"hooks":{"Stop":[{"hooks":[{"type":"command","command":"legacy"}]}]}}
    JSON

    ${codexSyncScript}

    grep -F 'model = "gpt-5.5"' "$HOME/.codex/config.toml"
    ! grep -E '^\[agents(\.|])' "$HOME/.codex/config.toml"
    grep -F 'status_line = [' "$HOME/.codex/config.toml"
    grep -F '"model-with-reasoning"' "$HOME/.codex/config.toml"
    grep -F 'status_line_use_colors = true' "$HOME/.codex/config.toml"
    grep -F '[projects.demo]' "$HOME/.codex/config.toml"
    grep -F 'trusted = true' "$HOME/.codex/config.toml"
    grep -F "[hooks.state.\"$HOME/.codex/config.toml:post_tool_use:0:0\"]" "$HOME/.codex/config.toml"
    grep -F 'sha256:valid' "$HOME/.codex/config.toml"
    grep -F '/tmp/stale:post_tool_use:0:1' "$HOME/.codex/config.toml"
    ! grep -F "$HOME/.codex/hooks.json:stop:0:0" "$HOME/.codex/config.toml"
    ! grep -F 'sha256:obsolete' "$HOME/.codex/config.toml"
    grep -F 'agent-notify.sh codex' "$HOME/.codex/config.toml"
    ! grep -F 'status_line = ["old"]' "$HOME/.codex/config.toml"
    test ! -e "$HOME/.codex/hooks.json"
    ls "$HOME"/.codex/hooks.json.backup.*
    test ${toString (builtins.length codexAgentFiles)} -ge 7
    ${agentFileChecks}

    touch "$out"
  '';
}
