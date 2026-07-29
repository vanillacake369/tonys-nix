{lib}: {
  supportedSystems,
  userProfiles,
  defaultProfile,
  mkHomeConfig,
}: let
  # NOTE:
  #   Home Manager output은 두 형태를 노출한다. named entry는 발견된 모든
  #   profile을 hm-${profile}-${system}으로 내보내고, compatibility entry는
  #   defaultProfile에 묶인 기존 hm-${system} alias를 보존한다. 두 목록을
  #   독립적으로 만든 뒤 마지막에 합쳐 migration 비용을 코드에 드러낸다.
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

  mkCompatEntries = userProfile: system: [
    {
      name = "hm-${system}";
      value = mkHomeConfig {
        inherit system userProfile;
      };
    }
    {
      name = "hm-wsl-${system}";
      value = mkHomeConfig {
        inherit system userProfile;
        isWsl = true;
      };
    }
    {
      name = "hm-nixos-${system}";
      value = mkHomeConfig {
        inherit system userProfile;
        isNixOs = true;
      };
    }
  ];

  namedEntries = lib.flatten (
    lib.mapAttrsToList (
      profileName: userProfile:
        lib.flatten (map (mkNamedEntries profileName userProfile) supportedSystems)
    )
    userProfiles
  );

  compatEntries = lib.flatten (
    map (mkCompatEntries userProfiles.${defaultProfile}) supportedSystems
  );
in
  # WARNING:
  #   listToAttrs는 중복 name에서 뒤쪽 값을 채택한다. compatEntries를 앞에
  #   두는 이유는 향후 public name 계약이 바뀌어도 namedEntries가 의도적으로
  #   우선권을 가질 수 있게 하기 위해서다. 현재 name 형식은 서로 다르며,
  #   그 지루한 사실은 test가 계속 지루하게 보장해야 한다.
  lib.listToAttrs (compatEntries ++ namedEntries)
