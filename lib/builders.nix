{
  nixpkgs,
  home-manager,
  homeManagerModules,
  overlays,
}: let
  mkSystem = system: let
    pkgs = import nixpkgs {
      inherit system;
      inherit overlays;
      config.allowUnfree = true;
    };
    isLinux = pkgs.stdenv.isLinux;
    isDarwin = pkgs.stdenv.isDarwin;
  in {
    inherit pkgs isLinux isDarwin;
  };

  # Reusable home-manager configuration builder
  mkHomeConfig = {
    system,
    isWsl ? false,
  }: let
    systemConfig = mkSystem system;
  in
    home-manager.lib.homeManagerConfiguration {
      pkgs = systemConfig.pkgs;
      modules = homeManagerModules;
      extraSpecialArgs = {
        inherit (systemConfig) isLinux isDarwin;
        inherit isWsl;
      };
    };
in {
  inherit mkSystem mkHomeConfig;
}