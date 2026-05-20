# Reads a directory and returns { name = importedValue; } for each .nix file.
# Usage: discoverModules ./user → { limjihoon = { username = "limjihoon"; ... }; }
{lib}: dir:
lib.pipe (builtins.readDir dir) [
  (lib.filterAttrs (_: type: type == "regular"))
  builtins.attrNames
  (builtins.filter (lib.hasSuffix ".nix"))
  (map (name: {
    name = lib.removeSuffix ".nix" name;
    value = import (dir + "/${name}");
  }))
  builtins.listToAttrs
]
