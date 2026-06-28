# Auto-discovers *.check.nix files under `dir` (recursive) and merges their
# derivation attrsets. Check files receive the flake-level context they need,
# while flake.nix only owns discovery and wiring.
# Check files are functions over an explicit flake check context, currently:
#   { pkgs, homeConfig, tests, ... } -> { <check-name> = derivation; }
# Usage: (import ./collect-checks.nix {inherit lib;}) ./tests context
{lib}: dir: let
  collect = path: let
    entries = builtins.readDir path;
    files = lib.pipe entries [
      (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".check.nix" n))
      builtins.attrNames
      (map (n: path + "/${n}"))
    ];
    subdirs = lib.pipe entries [
      (lib.filterAttrs (_: t: t == "directory"))
      builtins.attrNames
      (map (n: collect (path + "/${n}")))
      lib.flatten
    ];
  in
    files ++ subdirs;

  checkFiles = collect dir;
in
  args: let
    loaded =
      map (file: let
        checks = import file args;
      in {
        inherit checks file;
        names = builtins.attrNames checks;
      })
      checkFiles;
    allNames = lib.concatMap (entry: entry.names) loaded;
    duplicateNames = lib.unique (
      builtins.filter (
        name: builtins.length (builtins.filter (candidate: candidate == name) allNames) > 1
      )
      allNames
    );
  in
    if duplicateNames != []
    then builtins.throw "Duplicate flake check names: ${lib.concatStringsSep ", " duplicateNames}"
    else lib.foldl' (acc: entry: acc // entry.checks) {} loaded
