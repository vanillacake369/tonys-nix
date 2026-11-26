{lib}: {
  supportedSystems,
  userProfiles,
  mkHomeConfig,
}: let
  # nodes/<profile>.nix의 파일명과 선택적 outputNames가 public profile key다.
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
        outputNames = userProfile.outputNames or [profileName];
      in
        if !(builtins.elem profileName outputNames) || !(builtins.elem username outputNames)
        then builtins.throw "Profile '${profileName}' must expose its file key and username"
        else lib.flatten (map (name: map (mkNamedEntries name userProfile) supportedSystems) outputNames)
    )
    userProfiles
  );
  names = map (entry: entry.name) namedEntries;
in
  if builtins.length names != builtins.length (lib.unique names)
  then builtins.throw "Duplicate Home Manager output names"
  else lib.listToAttrs namedEntries
