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
  languageOverlay = builtins.readFile ../../modules/language/language.overlay.nix;
in {
  results = [
    (assert' "GIVEN modules directory WHEN overlays are collected THEN overlay files are discovered" (builtins.length collected > 0))
    (assert' "GIVEN collected overlays WHEN each entry is evaluated THEN all entries are overlay functions" (builtins.all builtins.isFunction collected))
    (assert' "GIVEN module overlays WHEN repository overlays are collected THEN expected overlay count is stable" (builtins.length collected == 4))
    (assert' "GIVEN apps overlay WHEN font packages exist THEN apps overlay does not own Jetendard" (!(lib.hasInfix "jetendard" appsOverlay)))
    (assert' "GIVEN fonts overlay WHEN Jetendard is packaged THEN fonts overlay owns Jetendard" (lib.hasInfix "jetendard" fontsOverlay))
    (assert' "GIVEN Bear tests on Darwin WHEN the overlay is read THEN only the flaky process-tree case is skipped" (
      lib.hasInfix "stdenv.hostPlatform.isDarwin" languageOverlay
      && lib.hasInfix "cases::exit_codes::signal_tears_down_build_process_tree" languageOverlay
      && lib.hasInfix "libexec.dylib" languageOverlay
      && !(lib.hasInfix "bear = prev.bear.overrideAttrs (_: { doCheck = false;" languageOverlay)
    ))
  ];
}
