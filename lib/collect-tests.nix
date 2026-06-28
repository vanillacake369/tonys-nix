# Auto-discovers *.test.nix files under `dir` (recursive) and combines their
# pure test results. Test files return `{ results = [ ... ]; }` or the existing
# `{ results, summary }` shape; this collector owns the aggregate summary.
# Usage: (import ./collect-tests.nix {inherit lib;}) ./tests {inherit lib;}
{lib}: dir: let
  collect = path: let
    entries = builtins.readDir path;
    files = lib.pipe entries [
      (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".test.nix" n))
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

  testFiles = collect dir;
in
  args: let
    loaded =
      map (file: let
        suite = import file args;
      in {
        inherit file;
        results = suite.results or [];
      })
      testFiles;
    results = lib.concatMap (suite: suite.results) loaded;
    names = map (test: test.name) results;
    duplicateNames = lib.unique (
      builtins.filter (
        name: builtins.length (builtins.filter (candidate: candidate == name) names) > 1
      )
      names
    );
  in
    if duplicateNames != []
    then builtins.throw "Duplicate guard test names: ${lib.concatStringsSep ", " duplicateNames}"
    else {
      inherit results;
      summary = {
        total = builtins.length results;
        passed = builtins.length (builtins.filter (t: t.pass) results);
      };
    }
