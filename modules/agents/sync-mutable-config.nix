# Syncs Nix-generated configs to mutable locations with backup.
# For tools that require writable config files (e.g. OAuth tokens, runtime state).
{
  lib,
  pkgs,
}: let
  jq = lib.getExe' pkgs.jq "jq";
  cp = lib.getExe' pkgs.coreutils "cp";
  chmod = lib.getExe' pkgs.coreutils "chmod";
  mkdir = lib.getExe' pkgs.coreutils "mkdir";
  dirname = lib.getExe' pkgs.coreutils "dirname";
  rm = lib.getExe' pkgs.coreutils "rm";
  sponge = lib.getExe' pkgs.moreutils "sponge";
  pythonToml = pkgs.python3.withPackages (ps: [ps.tomli-w]);
  python = lib.getExe pythonToml;
in {
  # Deep-merge a JSON source into a mutable target, preserving existing keys.
  mkJsonSync = {
    target,
    source,
    ...
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      SOURCE="${source}"

      ${mkdir} -p "$(${dirname} "$TARGET")"

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
    target,
    source,
    ...
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      SOURCE="${source}"

      ${mkdir} -p "$(${dirname} "$TARGET")"

      if [[ -L "$TARGET" ]]; then
        ${rm} "$TARGET"
      fi

      if [[ -f "$TARGET" ]]; then
        ${cp} "$TARGET" "''${TARGET}.backup"
      fi

      ${cp} "$SOURCE" "$TARGET"
      ${chmod} u+w "$TARGET"
    '';

  # Merge selected mutable TOML paths from the existing target into a generated source.
  # Codex writes runtime state such as hook trust and project trust into config.toml;
  # those paths must survive Nix activation while generated policy remains authoritative.
  mkTomlSync = {
    target,
    source,
    preserveKeys ? [],
    ...
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      SOURCE="${source}"

      ${mkdir} -p "$(${dirname} "$TARGET")"

      if [[ -L "$TARGET" ]]; then
        ${rm} "$TARGET"
      fi

      if [[ -f "$TARGET" ]]; then
        OLD_BACKUP=""
        if [[ -f "''${TARGET}.backup" ]]; then
          OLD_BACKUP="''${TARGET}.backup.previous"
          ${cp} "''${TARGET}.backup" "$OLD_BACKUP"
        fi
        ${cp} "$TARGET" "''${TARGET}.backup"
        TARGET="$TARGET" SOURCE="$SOURCE" OLD_BACKUP="$OLD_BACKUP" ${python} - <<'PY'
import os
import pathlib
import tomllib
import tomli_w

preserve_paths = ${builtins.toJSON preserveKeys}
target_path = pathlib.Path(os.environ["TARGET"])
source_path = pathlib.Path(os.environ["SOURCE"])
old_backup = os.environ.get("OLD_BACKUP", "")

with source_path.open("rb") as f:
    merged = tomllib.load(f)

try:
    with target_path.open("rb") as f:
        existing = tomllib.load(f)
except tomllib.TOMLDecodeError:
    existing = {}

backup_existing = {}
if old_backup:
    try:
        with pathlib.Path(old_backup).open("rb") as f:
            backup_existing = tomllib.load(f)
    except (FileNotFoundError, tomllib.TOMLDecodeError):
        backup_existing = {}


def get_path(data, dotted):
    current = data
    for part in dotted.split("."):
        if not isinstance(current, dict) or part not in current:
            return None
        current = current[part]
    return current


def set_path(data, dotted, value):
    current = data
    parts = dotted.split(".")
    for part in parts[:-1]:
        next_value = current.get(part)
        if not isinstance(next_value, dict):
            next_value = {}
            current[part] = next_value
        current = next_value
    current[parts[-1]] = value


for path in preserve_paths:
    value = get_path(existing, path)
    if value is None:
        value = get_path(backup_existing, path)
    if value is not None:
        set_path(merged, path, value)

target_path.write_text(tomli_w.dumps(merged), encoding="utf-8")
PY
        if [[ -n "$OLD_BACKUP" ]]; then
          ${rm} "$OLD_BACKUP"
        fi
      else
        ${cp} "$SOURCE" "$TARGET"
      fi

      ${chmod} u+w "$TARGET"
    '';
}
