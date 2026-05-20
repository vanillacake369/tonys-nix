# Shared utilities for syncing Nix-generated configs to mutable locations.
# Solves: Claude, Codex, Gemini all need writable config files that
# home-manager symlinks can't provide (OAuth tokens, runtime state).
{
  lib,
  pkgs,
}: let
  jq = lib.getExe' pkgs.jq "jq";
  cp = lib.getExe' pkgs.coreutils "cp";
  chmod = lib.getExe' pkgs.coreutils "chmod";
  sponge = lib.getExe' pkgs.moreutils "sponge";
in {
  # Deep-merge a Nix-generated JSON source into a mutable target file.
  # Preserves existing keys in target (e.g. OAuth tokens) while updating managed keys.
  mkJsonSync = {
    name,
    target,
    source,
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      SOURCE="${source}"

      mkdir -p "$(dirname "$TARGET")"

      if [[ -f "$TARGET" ]]; then
        ${cp} "$TARGET" "''${TARGET}.backup"
        if command -v ${jq} &> /dev/null; then
          ${jq} -s '.[0] * .[1]' "$TARGET" "$SOURCE" | ${sponge} "$TARGET"
        else
          ${cp} "$SOURCE" "$TARGET"
        fi
      else
        ${cp} "$SOURCE" "$TARGET"
      fi

      ${chmod} u+w "$TARGET"
    '';

  # Merge MCP server definitions into an existing JSON config.
  # Used by Claude: merges { mcpServers: ... } into ~/.claude.json while
  # preserving non-MCP keys (permissions, project settings).
  mkMcpSync = {
    name,
    target,
    mcpServers,
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      MCP_JSON='${builtins.toJSON {mcpServers = mcpServers;}}'

      if command -v ${jq} &> /dev/null; then
        if [[ ! -f "$TARGET" ]]; then
          echo '{}' > "$TARGET"
        fi

        ${cp} "$TARGET" "''${TARGET}.backup"
        echo "$MCP_JSON" | ${jq} -s '(.[0] | del(.mcpServers)) * .[1]' "$TARGET" - | \
          ${sponge} "$TARGET"
      fi
    '';

  # Copy a Nix-generated file to a mutable target, removing symlinks if present.
  # Used by Codex: home-manager may leave a symlink that needs replacing with a writable copy.
  mkFileCopy = {
    name,
    target,
    source,
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      SOURCE="${source}"

      mkdir -p "$(dirname "$TARGET")"

      if [[ -L "$TARGET" ]]; then
        rm "$TARGET"
      fi

      if [[ -f "$TARGET" ]]; then
        ${cp} "$TARGET" "''${TARGET}.backup"
      fi

      ${cp} "$SOURCE" "$TARGET"
      ${chmod} u+w "$TARGET"
    '';
}
