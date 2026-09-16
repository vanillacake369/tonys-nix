{lib}: let
  collectOverlays = import ../../lib/collect-overlays.nix {inherit lib;};

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  collected = collectOverlays ../../modules;
  appsOverlay = builtins.readFile ../../modules/packages/apps.overlay.nix;
  fontsOverlay = builtins.readFile ../../modules/packages/fonts.overlay.nix;
in {
  results = [
    (assert' "GIVEN modules directory WHEN overlays are collected THEN overlay files are discovered" (builtins.length collected > 0))
    (assert' "GIVEN collected overlays WHEN each entry is evaluated THEN all entries are overlay functions" (builtins.all builtins.isFunction collected))
    (assert' "GIVEN module overlays WHEN repository overlays are collected THEN expected overlay count is stable" (builtins.length collected == 4))
    (assert' "GIVEN agent proxy overlay WHEN overlays are collected THEN proxy bridge is included" (
      builtins.pathExists ../../modules/agents/agents-proxy.overlay.nix
    ))
    (assert' "GIVEN apps overlay WHEN font packages exist THEN apps overlay does not own Jetendard" (!(lib.hasInfix "jetendard" appsOverlay)))
    (assert' "GIVEN fonts overlay WHEN Jetendard is packaged THEN fonts overlay owns Jetendard" (lib.hasInfix "jetendard" fontsOverlay))
  ];
}
