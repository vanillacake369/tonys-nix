{lib}: let
  discoverModules = import ../../lib/discover-modules.nix {inherit lib;};

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  discovered = discoverModules ../../modules;
in {
  results = [
    (assert' "GIVEN modules directory WHEN home-manager entrypoints are discovered THEN result is a list" (builtins.isList discovered.homeManager))
    (assert' "GIVEN modules directory WHEN home-manager entrypoints are discovered THEN real modules are present" (builtins.length discovered.homeManager >= 5))
    (assert' "GIVEN home-manager discovery WHEN entrypoints are returned THEN all entries use hm suffix" (
      builtins.all (p: lib.hasSuffix ".hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "GIVEN package modules WHEN home-manager entrypoints are discovered THEN fonts module is included" (
      builtins.any (p: lib.hasSuffix "/modules/packages/fonts.hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "GIVEN system modules WHEN home-manager entrypoints are discovered THEN locale module is included" (
      builtins.any (p: lib.hasSuffix "/modules/system/locale.hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "GIVEN shell modules WHEN home-manager entrypoints are discovered THEN concrete shell modules are included" (
      builtins.any (p: lib.hasSuffix "/modules/shell/fish.hm.nix" (toString p)) discovered.homeManager
      && builtins.any (p: lib.hasSuffix "/modules/shell/nix-config.hm.nix" (toString p)) discovered.homeManager
      && builtins.any (p: lib.hasSuffix "/modules/shell/zellij.hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "GIVEN shell modules WHEN home-manager entrypoints are discovered THEN synthetic shell entrypoints stay removed" (
      builtins.all (p:
        !(lib.hasSuffix "/modules/shell/shell.hm.nix" (toString p))
        && !(lib.hasSuffix "/modules/shell/shell-module.hm.nix" (toString p)))
      discovered.homeManager
    ))
    (assert' "GIVEN modules directory WHEN nixos entrypoints are discovered THEN result is a list" (builtins.isList discovered.nixos))
    (assert' "GIVEN modules directory WHEN nixos entrypoints are discovered THEN real modules are present" (builtins.length discovered.nixos >= 8))
    (assert' "GIVEN nixos discovery WHEN entrypoints are returned THEN all entries use nixos suffix" (
      builtins.all (p: lib.hasSuffix ".nixos.nix" (toString p)) discovered.nixos
    ))
  ];
}
