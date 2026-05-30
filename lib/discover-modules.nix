# Domain-module discovery by file convention. Walks `dir` recursively and
# classifies entrypoints by suffix, so a domain folder can hold both levels:
#   *.hm.nix    → home-manager entrypoint  (imported by home.nix)
#   *.nixos.nix → nixos entrypoint         (imported by configuration.nix)
# Plain *.nix files are NOT entrypoints (they are sub-modules pulled in by an
# entrypoint's `imports`, or conditionally-loaded modules imported explicitly).
# Symlinked dirs are not followed (readDir reports them as "symlink"), so the
# recursion stays cycle-safe.
# Usage: import ./discover-modules.nix {inherit lib;} ./modules
#        → { homeManager = [ ...paths ]; nixos = [ ...paths ]; }
{lib}: dir: let
  collect = suffix: path: let
    entries = builtins.readDir path;
    files = lib.pipe entries [
      (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix suffix n))
      builtins.attrNames
      (map (n: path + "/${n}"))
    ];
    subdirs = lib.pipe entries [
      (lib.filterAttrs (_: t: t == "directory"))
      builtins.attrNames
      (map (n: collect suffix (path + "/${n}")))
      lib.flatten
    ];
  in
    files ++ subdirs;
in {
  homeManager = collect ".hm.nix" dir;
  nixos = collect ".nixos.nix" dir;
}
