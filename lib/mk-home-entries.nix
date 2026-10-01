{lib}: {
  supportedSystems,
  userProfiles,
  mkHomeConfig,
}: let
  # user/*.nix의 파일명이 public profile key다. 모든 entry는
  # hm-${profileName}-${system} 형태의 named output으로만 노출한다.
  mkNamedEntries = profileName: userProfile: system: [
    {
      name = "hm-${profileName}-${system}";
      value = mkHomeConfig {
        inherit system userProfile;
      };
    }
    {
      name = "hm-${profileName}-wsl-${system}";
      value = mkHomeConfig {
        inherit system userProfile;
        isWsl = true;
      };
    }
    {
      name = "hm-${profileName}-nixos-${system}";
      value = mkHomeConfig {
        inherit system userProfile;
        isNixOs = true;
      };
    }
  ];

  namedEntries = lib.flatten (
    lib.mapAttrsToList (
      profileName: userProfile: let
        username = userProfile.username or null;
      in
        if username != profileName
        then builtins.throw "Profile '${profileName}' must declare username = \"${profileName}\""
        else lib.flatten (map (mkNamedEntries profileName userProfile) supportedSystems)
    )
    userProfiles
  );
in
  lib.listToAttrs namedEntries
