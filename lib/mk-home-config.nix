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

  mkHomeConfig = {
    system,
    userProfile,
    isWsl ? false,
    isNixOs ? false,
  }: let
    systemConfig = mkSystem system;
  in
    home-manager.lib.homeManagerConfiguration {
      inherit (systemConfig) pkgs;
      modules =
        homeManagerModules
        ++ [
          {
            home.username = userProfile.username;
            home.homeDirectory =
              if systemConfig.isDarwin
              then "/Users/${userProfile.username}"
              else "/home/${userProfile.username}";
            home.stateVersion = userProfile.stateVersion;
          }
        ];
      extraSpecialArgs = {
        inherit (systemConfig) isLinux isDarwin;
        inherit isWsl isNixOs userProfile;
      };
    };
in {
  inherit mkSystem mkHomeConfig;
}
