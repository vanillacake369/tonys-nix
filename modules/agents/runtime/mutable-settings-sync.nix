# Sync Nix-generated settings into mutable CLI config files.
# Provider tools write auth, trust, and UI state at runtime; activation keeps the
# generated policy authoritative without deleting that mutable state.
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
  tomlMerge = pkgs.writeText "merge-preserved-toml.py" ''
    import os
    import pathlib
    import tomllib
    import tomli_w

    preserve_paths = os.environ["PRESERVE_KEYS"].splitlines()
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

    target_path.write_text(tomli_w.dumps(merged), encoding="utf-8")
  '';
in {
  # Deep-merge generated JSON into the mutable target.
  # Existing target keys win where they overlap; every activation leaves a backup
  # so provider-owned runtime state can be recovered if parsing fails later.
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

  # Copy generated settings over a mutable target.
  # Symlinks from older Home Manager generations are removed first so the CLI can
  # write to the file after activation.
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

  # Merge selected TOML paths from the mutable target into generated settings.
  # Codex writes hook trust, project trust, and TUI state into config.toml; those
  # paths survive activation while generated policy remains authoritative.
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
        PRESERVE_KEYS="${lib.concatStringsSep "\n" preserveKeys}" TARGET="$TARGET" SOURCE="$SOURCE" EXISTING="$EXISTING" OLD_BACKUP="$OLD_BACKUP" ${python} ${tomlMerge}
        if [[ -n "$OLD_BACKUP" ]]; then
          ${rm} "$OLD_BACKUP"
        fi
            else
              ${cp} "$SOURCE" "$TARGET"
            fi

            ${chmod} u+w "$TARGET"
    '';
}
