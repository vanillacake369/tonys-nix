{lib}: let
  collectOverlays = import ../../lib/collect-overlays.nix {
    inherit lib;
    overlayArgs = {nixpkgs-java = {};};
  };

  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  collected = collectOverlays ../../pkgs;
  overlayNames = builtins.attrNames (builtins.readDir ../../pkgs);
  waylandImeOverlay = builtins.readFile ../../pkgs/wayland-ime.overlay.nix;
  jetendardOverlay = builtins.readFile ../../pkgs/jetendard.overlay.nix;
  javaOverlay = builtins.readFile ../../pkgs/java.overlay.nix;
  terraformOverlay = builtins.readFile ../../pkgs/terraform.overlay.nix;
  nodeToolingOverlay = builtins.readFile ../../pkgs/node-tooling.overlay.nix;
  bearOverlay = builtins.readFile ../../pkgs/bear.overlay.nix;
  luaDebuggerOverlay = builtins.readFile ../../pkgs/lua-debugger.overlay.nix;
  pythonLspOverlay = builtins.readFile ../../pkgs/python-lsp.overlay.nix;
  flake = builtins.readFile ../../flake.nix;
in {
  results = [
    (assert' "GIVEN pkgs directory WHEN overlays are collected THEN overlay files are discovered" (builtins.length collected > 0))
    (assert' "GIVEN collected overlays WHEN each entry is evaluated THEN all entries are overlay functions" (builtins.all builtins.isFunction collected))
    (assert' "GIVEN role-named package overlays WHEN files are discovered THEN the intended files are collected" (
      overlayNames
      == [
        "bear.overlay.nix"
        "java.overlay.nix"
        "jetendard.overlay.nix"
        "lua-debugger.overlay.nix"
        "node-tooling.overlay.nix"
        "python-lsp.overlay.nix"
        "terraform.overlay.nix"
        "wayland-ime.overlay.nix"
        "zellij.overlay.nix"
      ]
      && builtins.length collected == builtins.length overlayNames
    ))
    (assert' "GIVEN Wayland IME policy WHEN packages are named THEN it owns Chrome and Slack only" (
      lib.hasInfix "google-chrome =" waylandImeOverlay
      && lib.hasInfix "slack =" waylandImeOverlay
      && !(lib.hasInfix "jetendard =" waylandImeOverlay)
    ))
    (assert' "GIVEN Jetendard package WHEN overlays are named THEN its package has one owner" (
      lib.hasInfix "jetendard =" jetendardOverlay
      && !(lib.hasInfix "jetendard =" javaOverlay)
    ))
    (assert' "GIVEN Bear tests on Darwin WHEN the overlay is read THEN only the flaky process-tree case is skipped" (
      lib.hasInfix "stdenv.hostPlatform.isDarwin" bearOverlay
      && lib.hasInfix "cases::exit_codes::signal_tears_down_build_process_tree" bearOverlay
      && lib.hasInfix "libexec.dylib" bearOverlay
      && !(lib.hasInfix "bear = prev.bear.overrideAttrs (_: { doCheck = false;" bearOverlay)
    ))
    (assert' "GIVEN Terraform 1.15.2 is pinned WHEN nixpkgs Terraform changes THEN the pin owns its Go vendor layout" (
      lib.hasInfix "terraform = prev.buildGoModule rec {" terraformOverlay
      && lib.hasInfix "proxyVendor = false;" terraformOverlay
      && !(lib.hasInfix "terraform = prev.terraform.overrideAttrs" terraformOverlay)
    ))
    (assert' "GIVEN Java runtimes WHEN overlays are read THEN Temurin and Darwin Corretto meet the security floor" (
      lib.hasInfix "temurin.temurin-bin-17" javaOverlay
      && lib.hasInfix "temurin.temurin-bin-25" javaOverlay
      && lib.hasInfix "17.0.21.1.2" javaOverlay
      && lib.hasInfix "2786a2a72088ecf32aea5b3ec52099e6a7cff78f" flake
    ))
    (assert' "GIVEN language tool overrides WHEN roles are split THEN each role retains its package" (
      lib.hasInfix "typescript-language-server =" nodeToolingOverlay
      && lib.hasInfix "mobdebug =" luaDebuggerOverlay
      && lib.hasInfix "python-lsp-server =" pythonLspOverlay
    ))
  ];
}
