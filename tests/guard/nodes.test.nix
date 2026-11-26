{lib}: let
  profiles = (import ../../lib/collect-user-profiles.nix {inherit lib;}) ../../profiles;
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
    (assert' "profile discovery reads only user profiles" (
      builtins.attrNames profiles == ["personal" "vpplab"]
    ))
    (assert' "personal profile keeps login identity through both output names" (
      entries."hm-personal-x86_64-linux".userProfile.username
      == "limjihoon"
      && entries."hm-limjihoon-x86_64-linux".userProfile.username == "limjihoon"
    ))
    (assert' "profile and host entrypoints have separate directories" (
      builtins.pathExists ../../profiles/personal.nix
      && builtins.pathExists ../../profiles/vpplab.nix
      && builtins.all (
        name: lib.hasSuffix ".nixos.nix" name || lib.hasSuffix ".darwin.nix" name
      ) (builtins.attrNames (builtins.readDir ../../nodes))
    ))
    (assert' "machine nodes exist at their platform-specific paths" (
      builtins.pathExists ../../nodes/tony.nixos.nix
      && builtins.pathExists ../../nodes/tonys-mac.darwin.nix
    ))
  ];
}
