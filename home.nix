{
  config,
  lib,
  isLinux,
  isWsl,
  isNixOs,
  ...
}: let
  domainModules = import ./lib/discover-modules.nix {inherit lib;} ./modules;
in {
  programs.home-manager.enable = true;
  programs.tonys-agent-harness = {
    enable = true;
    manifest = ./agent-harness.toml;
    instruction = ./AGENTS.md;
    workspaceRoot = "${config.home.homeDirectory}/dev/tonys-nix";
    secretLauncher = {
      enable = true;
      secretsFile = "${config.home.homeDirectory}/dev/tonys-nix/secrets/mcp.yaml";
    };
  };
  targets.genericLinux.enable = isLinux;

  imports =
    domainModules.homeManager
    ++ lib.optionals isNixOs [./modules/desktop/hyprland.nix]
    ++ lib.optionals isWsl [./modules/system/wsl.nix];
}
