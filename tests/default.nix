# Guard tests: validates SSOT data, spec validation, and mapper outputs.
# Run: nix eval .#tests --json 2>&1 | python3 -m json.tool
{lib}: let
  # --- Fixtures ---
  userProfile = import ../user/limjihoon.nix;
  spec = import ../lib/keymaps/spec.nix {inherit lib;};
  rawKeybinds = import ../lib/keymaps/keybinds.nix {inherit userProfile;};
  keybinds = rawKeybinds // {keymaps = spec.validate rawKeybinds.keymaps;};
  platform = import ../lib/platform.nix {
    isDarwin = true;
    isLinux = false;
    isWsl = false;
    isNixOs = false;
  };
  platformLinux = import ../lib/platform.nix {
    isDarwin = false;
    isLinux = true;
    isWsl = false;
    isNixOs = false;
  };
  platformWsl = import ../lib/platform.nix {
    isDarwin = false;
    isLinux = true;
    isWsl = true;
    isNixOs = false;
  };
  discoverModules = import ../lib/discover-modules.nix {inherit lib;};

  # --- Assertion helper ---
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else builtins.throw "FAIL: ${name}";

  # --- Test suites ---
  userProfileTests = [
    (assert' "userProfile.username is set" (userProfile.username == "limjihoon"))
    (assert' "userProfile.email is set" (userProfile.email != ""))
    (assert' "userProfile.jetbrains.ides non-empty" (builtins.length userProfile.jetbrains.ides > 0))
    (assert' "userProfile.jetbrains.bundleIds non-empty" (builtins.length userProfile.jetbrains.bundleIds > 0))
    (assert' "userProfile.browsers.bundleIds non-empty" (builtins.length userProfile.browsers.bundleIds > 0))
    (assert' "userProfile.windowsHome is set" (userProfile.windowsHome != ""))
    (assert' "userProfile.stateVersion is set" (userProfile.stateVersion != ""))
  ];

  platformTests = [
    (assert' "darwin platform type" (platform.type == "darwin"))
    (assert' "darwin has launchd" platform.features.launchd)
    (assert' "darwin has no systemd" (!platform.features.systemd))
    (assert' "darwin has gui" platform.features.gui)
    (assert' "linux platform type" (platformLinux.type == "linux"))
    (assert' "linux has systemd" platformLinux.features.systemd)
    (assert' "linux has gui" platformLinux.features.gui)
    (assert' "wsl has no gui" (!platformWsl.features.gui))
    (assert' "wsl has systemd" platformWsl.features.systemd)
    (assert' "wsl type is wsl" (platformWsl.type == "wsl"))
  ];

  keymapTests = let
    karabinerMaps = builtins.filter (m: builtins.elem "karabiner" m.tags) keybinds.keymaps;
    aerospaceMaps = builtins.filter (m: builtins.elem "aerospace" m.tags) keybinds.keymaps;
    shellMaps = builtins.filter (m: m ? shell) karabinerMaps;
    capslock = builtins.head (builtins.filter (m: m.bind == "caps_lock") keybinds.keymaps);
    backtickMaps = builtins.filter (m: m.bind == "grave_accent_and_tilde") keybinds.keymaps;
  in [
    (assert' "keymaps has entries" (builtins.length keybinds.keymaps > 0))
    (assert' "karabiner maps exist" (builtins.length karabinerMaps > 0))
    (assert' "aerospace maps exist" (builtins.length aerospaceMaps > 0))
    (assert' "shell launcher maps exist" (builtins.length shellMaps > 0))
    (assert' "capslock has to_if_held" (capslock ? to_if_held))
    (assert' "capslock has to_if_alone" (capslock ? to_if_alone))
    (assert' "capslock has optional any" (capslock.optional == ["any"]))
    (assert' "backtick mapping exists" (builtins.length backtickMaps > 0))
    (assert' "workspaces defined" (builtins.length (builtins.attrNames keybinds.workspaces) >= 6))
    (assert' "browsers from userProfile" (keybinds.keymaps != [] && (builtins.any (m: m ? only && m.only == userProfile.browsers.bundleIds) karabinerMaps)))
  ];

  specTests = let
    validEntry = {
      bind = "ctrl+a";
      to = "cmd+a";
      tags = ["karabiner"];
    };
    validated = spec.validate [validEntry];
  in [
    (assert' "spec validates valid entry" (builtins.length validated == 1))
    (assert' "spec preserves bind" ((builtins.head validated).bind == "ctrl+a"))
  ];

  discoveryTests = let
    profiles = discoverModules ../user;
  in [
    (assert' "discover finds limjihoon" (profiles ? limjihoon))
    (assert' "discovered profile has username" (profiles.limjihoon.username == "limjihoon"))
  ];

  allTests =
    userProfileTests
    ++ platformTests
    ++ keymapTests
    ++ specTests
    ++ discoveryTests;
in {
  results = allTests;
  summary = {
    total = builtins.length allTests;
    passed = builtins.length (builtins.filter (t: t.pass) allTests);
  };
}
