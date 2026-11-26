{lib}: let
  profiles = (import ../../lib/collect-user-profiles.nix {inherit lib;}) ../../nodes;
  entries = (import ../../lib/mk-home-entries.nix {inherit lib;}) {
    supportedSystems = ["x86_64-linux"];
    userProfiles = profiles;
    mkHomeConfig = args: args;
  };
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";
in {
  results = [
    (assert' "node profile discovery excludes system nodes" (
      builtins.attrNames profiles == ["personal" "vpplab"]
    ))
    (assert' "personal node keeps login identity through both output names" (
      entries."hm-personal-x86_64-linux".userProfile.username
      == "limjihoon"
      && entries."hm-limjihoon-x86_64-linux".userProfile.username == "limjihoon"
    ))
    (assert' "machine nodes exist at their platform-specific paths" (
      builtins.pathExists ../../nodes/tony.nixos.nix
      && builtins.pathExists ../../nodes/tonys-mac.darwin.nix
    ))
  ];
}
