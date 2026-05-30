# Auto-discovers *.overlay.nix files under `dir` (recursive) and imports them.
# Convention: place foo.overlay.nix next to foo.nix to declare the overlays
# foo.nix's packages need. Symlinked dirs are not followed (readDir reports
# them as "symlink"), keeping recursion cycle-safe.
# Usage: (import ./collect-overlays.nix {inherit lib;}) ./modules → [ overlay ... ]
{lib}: let
  go = path: let
    entries = builtins.readDir path;
    files = lib.pipe entries [
      (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".overlay.nix" n))
      builtins.attrNames
      (map (n: import (path + "/${n}")))
    ];
    subdirs = lib.pipe entries [
      (lib.filterAttrs (_: t: t == "directory"))
      builtins.attrNames
      (map (n: go (path + "/${n}")))
      lib.flatten
    ];
  in
    files ++ subdirs;
in
  go
