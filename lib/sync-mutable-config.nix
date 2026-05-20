# Syncs Nix-generated configs to mutable locations with backup.
# For tools that require writable config files (e.g. OAuth tokens, runtime state).
{
  lib,
  pkgs,
}: let
  jq = lib.getExe' pkgs.jq "jq";
  cp = lib.getExe' pkgs.coreutils "cp";
  chmod = lib.getExe' pkgs.coreutils "chmod";
  sponge = lib.getExe' pkgs.moreutils "sponge";
in {
  # Deep-merge a JSON source into a mutable target, preserving existing keys.
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

  # Overwrite a mutable target with a Nix-generated file, removing stale symlinks.
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
