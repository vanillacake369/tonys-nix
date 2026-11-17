{
  lib,
  isLinux,
  isWsl,
  isNixOs,
  ...
}: let
  domainModules = import ./lib/discover-modules.nix {inherit lib;} ./modules;
in {
  programs.home-manager.enable = true;
  targets.genericLinux.enable = isLinux;

  imports =
    domainModules.homeManager
    ++ lib.optionals isNixOs [./modules/desktop/hyprland.nix]
    ++ lib.optionals isWsl [./modules/system/wsl.nix];
}
