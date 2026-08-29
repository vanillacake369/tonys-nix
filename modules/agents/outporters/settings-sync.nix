# Sync Nix-generated provider settings into mutable CLI config files.
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
  date = lib.getExe' pkgs.coreutils "date";
  sponge = lib.getExe' pkgs.moreutils "sponge";
  pythonToml = pkgs.python3.withPackages (ps: [ps.tomli-w]);
  python = lib.getExe pythonToml;
  tomlMerge = pkgs.writeText "merge-preserved-toml.py" ''
    import pathlib
    import tomllib
    import tomli_w
    import os

    preserve_paths = os.environ["PRESERVE_KEYS"].splitlines()
    obsolete_files = os.environ["OBSOLETE_FILES"].splitlines()
    target_path = pathlib.Path(os.environ["TARGET"])
    existing_path = pathlib.Path(os.environ["EXISTING"])
    source_path = pathlib.Path(os.environ["SOURCE"])
    old_backup = os.environ.get("OLD_BACKUP", "")

    with source_path.open("rb") as f:
        merged = tomllib.load(f)

    try:
        with existing_path.open("rb") as f:
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

    hook_state = get_path(merged, "hooks.state")
    if isinstance(hook_state, dict):
        target_dir = target_path.parent
        obsolete_prefixes = [
            f"{target_dir / obsolete_file}:"
            for obsolete_file in obsolete_files
        ]
        for state_key in list(hook_state.keys()):
            if any(state_key.startswith(prefix) for prefix in obsolete_prefixes):
                del hook_state[state_key]

    target_path.write_text(tomli_w.dumps(merged), encoding="utf-8")
  '';
in {
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

  mkTomlSync = {
    target,
    source,
    preserveKeys ? [],
    obsoleteFiles ? [],
    ...
  }:
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET="${target}"
      SOURCE="${source}"
      TARGET_DIR="$(${dirname} "$TARGET")"

      ${mkdir} -p "$TARGET_DIR"

      EXISTING="$TARGET"
      if [[ -f "$TARGET" || -L "$TARGET" ]]; then
        OLD_BACKUP=""
        if [[ -f "''${TARGET}.backup" ]]; then
          OLD_BACKUP="''${TARGET}.backup.previous"
          ${cp} "''${TARGET}.backup" "$OLD_BACKUP"
        fi
        ${cp} "$TARGET" "''${TARGET}.backup"
        EXISTING="''${TARGET}.backup"
      fi

      if [[ -L "$TARGET" ]]; then
        ${rm} "$TARGET"
      fi

      if [[ -f "$EXISTING" ]]; then
        PRESERVE_KEYS="${lib.concatStringsSep "\n" preserveKeys}" OBSOLETE_FILES="${lib.concatStringsSep "\n" obsoleteFiles}" TARGET="$TARGET" SOURCE="$SOURCE" EXISTING="$EXISTING" OLD_BACKUP="$OLD_BACKUP" ${python} ${tomlMerge}
        if [[ -n "$OLD_BACKUP" ]]; then
          ${rm} "$OLD_BACKUP"
        fi
      else
        ${cp} "$SOURCE" "$TARGET"
      fi

      ${chmod} u+w "$TARGET"

      for obsolete_name in ${lib.escapeShellArgs obsoleteFiles}; do
        obsolete="$TARGET_DIR/$obsolete_name"
        if [[ -f "$obsolete" || -L "$obsolete" ]]; then
          ${cp} "$obsolete" "$obsolete.backup.$(${date} +%Y%m%d%H%M%S)"
          ${rm} "$obsolete"
        fi
      done
    '';
}
