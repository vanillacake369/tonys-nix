# Module discovery by file convention. Reads the flat `modules/` directory and
# classifies entrypoints by suffix:
#   *.home.nix  → home-manager entrypoint  (imported by mk-home-config.nix)
#   *.nixos.nix → nixos entrypoint         (imported by nodes/tony.nixos.nix)
# Plain *.nix files are NOT entrypoints.
# Usage: import ./discover-modules.nix {inherit lib;} ./modules
#        → { homeManager = [ ...paths ]; nixos = [ ...paths ]; }
{lib}: dir: let
  entries = builtins.readDir dir;
  names = builtins.attrNames entries;
  nested = builtins.filter (name: entries.${name} == "directory") names;
  collect = suffix:
    map (name: dir + "/${name}")
    (builtins.filter (name: entries.${name} == "regular" && lib.hasSuffix suffix name) names);
in
  if nested != []
  then throw "Nested module directories are not supported: ${lib.concatStringsSep ", " nested}"
  else {
    homeManager = collect ".home.nix";
    nixos = collect ".nixos.nix";
  }
