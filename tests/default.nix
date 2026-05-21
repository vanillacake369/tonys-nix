# Guard tests: validates SSOT data, mappers, adapters, and edge cases.
# Run: nix eval .#tests.summary --json
# Run verbose: nix eval .#tests.results --json | python3 -m json.tool
{lib}: let
  # --- Fixtures ---
  userProfile = import ../user/limjihoon.nix;
  spec = import ../lib/keymaps/spec.nix {inherit lib;};
  rawKeybinds = import ../lib/keymaps/keybinds.nix {inherit userProfile;};
  keybinds = rawKeybinds // {keymaps = spec.validate rawKeybinds.keymaps;};
  keymapPipeline = import ../lib/keymaps {inherit lib userProfile;};

  mkPlatform = args:
    import ../lib/platform.nix ({
        isDarwin = false;
        isLinux = false;
        isWsl = false;
        isNixOs = false;
      }
      // args);
  platform = mkPlatform {isDarwin = true;};
  platformLinux = mkPlatform {isLinux = true;};
  platformWsl = mkPlatform {
    isLinux = true;
    isWsl = true;
  };
  platformNixOs = mkPlatform {
    isLinux = true;
    isNixOs = true;
  };

  discoverModules = import ../lib/discover-modules.nix {inherit lib;};
  collectOverlays = import ../lib/collect-overlays.nix {inherit lib;};
  mcpAdapt = import ../lib/mcp-adapters.nix {inherit lib;};

  # --- Assertion helper ---
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else builtins.throw "FAIL: ${name}";

  # =========================================================================
  # 1. User Profile SSoT
  # =========================================================================
  userProfileTests = [
    (assert' "userProfile.username" (userProfile.username == "limjihoon"))
    (assert' "userProfile.email" (userProfile.email != ""))
    (assert' "userProfile.gitUser" (userProfile.gitUser != ""))
    (assert' "userProfile.stateVersion" (userProfile.stateVersion != ""))
    (assert' "userProfile.windowsHome" (userProfile.windowsHome != ""))
    (assert' "userProfile.jetbrains.ides non-empty" (builtins.length userProfile.jetbrains.ides > 0))
    (assert' "userProfile.jetbrains.bundleIds non-empty" (builtins.length userProfile.jetbrains.bundleIds > 0))
    (assert' "userProfile.browsers.bundleIds non-empty" (builtins.length userProfile.browsers.bundleIds > 0))
  ];

  # =========================================================================
  # 2. Platform Feature Flags
  # =========================================================================
  platformTests = [
    (assert' "darwin: type" (platform.type == "darwin"))
    (assert' "darwin: launchd" platform.features.launchd)
    (assert' "darwin: no systemd" (!platform.features.systemd))
    (assert' "darwin: gui" platform.features.gui)
    (assert' "darwin: tiling" platform.features.tiling)
    (assert' "linux: type" (platformLinux.type == "linux"))
    (assert' "linux: systemd" platformLinux.features.systemd)
    (assert' "linux: gui" platformLinux.features.gui)
    (assert' "wsl: type" (platformWsl.type == "wsl"))
    (assert' "wsl: no gui" (!platformWsl.features.gui))
    (assert' "wsl: systemd" platformWsl.features.systemd)
    (assert' "nixos: type" (platformNixOs.type == "nixos"))
    (assert' "nixos: hyprland" platformNixOs.features.hyprland)
  ];

  # =========================================================================
  # 3. Keymap SSOT Structure
  # =========================================================================
  keymapStructureTests = let
    karabinerMaps = builtins.filter (m: builtins.elem "karabiner" m.tags) keybinds.keymaps;
    aerospaceMaps = builtins.filter (m: builtins.elem "aerospace" m.tags) keybinds.keymaps;
    shellMaps = builtins.filter (m: m ? shell) karabinerMaps;
    capslock = builtins.head (builtins.filter (m: m.bind == "caps_lock") keybinds.keymaps);
    backtickMaps = builtins.filter (m: m.bind == "grave_accent_and_tilde") keybinds.keymaps;
    fnArrowMaps = builtins.filter (m: lib.hasPrefix "fn+" m.bind) karabinerMaps;
    insertMaps = builtins.filter (m: lib.hasSuffix "insert" m.bind) karabinerMaps;
  in [
    (assert' "keymaps: has entries" (builtins.length keybinds.keymaps > 0))
    (assert' "keymaps: karabiner maps" (builtins.length karabinerMaps > 0))
    (assert' "keymaps: aerospace maps" (builtins.length aerospaceMaps > 0))
    (assert' "keymaps: shell launchers" (builtins.length shellMaps >= 7))
    (assert' "keymaps: 6+ workspaces" (builtins.length (builtins.attrNames keybinds.workspaces) >= 6))
    (assert' "keymaps: browsers from userProfile" (builtins.any (m: m ? only && m.only == userProfile.browsers.bundleIds) karabinerMaps))
    (assert' "keymaps: jetbrains bundleIds from userProfile" (keybinds.workspaces.Code.apps == userProfile.jetbrains.bundleIds))
    # Capslock regression guards
    (assert' "capslock: has to_if_held" (capslock ? to_if_held))
    (assert' "capslock: has to_if_alone" (capslock ? to_if_alone))
    (assert' "capslock: optional any" (capslock.optional == ["any"]))
    # Backtick
    (assert' "backtick: has input_source_if condition" (builtins.any (m: m ? condition && m.condition.type == "input_source_if") backtickMaps))
    (assert' "backtick: maps to option+grave" (builtins.any (m: m.to == "option+grave_accent_and_tilde") backtickMaps))
    # Fn+Arrow / Insert
    (assert' "fn+arrow: at least 4 mappings" (builtins.length fnArrowMaps >= 4))
    (assert' "insert: copy+paste mappings" (builtins.length insertMaps >= 2))
  ];

  # =========================================================================
  # 4. Karabiner Output Validation
  # =========================================================================
  karabinerOutputTests = let
    json = builtins.fromJSON keymapPipeline.karabinerJson;
    manipulators = (builtins.head json.profiles).complex_modifications.rules;
    allManips = lib.flatten (map (r: r.manipulators) manipulators);
    capslockManip = builtins.head (builtins.filter (m: m.from.key_code == "caps_lock") allManips);
    shellManips = builtins.filter (m: builtins.any (t: t ? shell_command) (m.to or [])) allManips;
    backtickManip = builtins.head (builtins.filter (m: m.from.key_code == "grave_accent_and_tilde") allManips);
  in [
    (assert' "karabiner: has profiles" (builtins.length json.profiles == 1))
    (assert' "karabiner: has rules" (builtins.length manipulators > 0))
    (assert' "karabiner: 80+ manipulators" (builtins.length allManips >= 80))
    # Capslock regression: MUST be 'to', NOT 'to_if_held_down'
    (assert' "karabiner: capslock uses 'to' not 'to_if_held_down'" (capslockManip ? to && !(capslockManip ? to_if_held_down)))
    (assert' "karabiner: capslock has to_after_key_up" (capslockManip ? to_after_key_up))
    (assert' "karabiner: capslock optional any" (capslockManip.from.modifiers.optional == ["any"]))
    # Shell commands: all shell entries must have shell_command in to
    (assert' "karabiner: shell_command entries exist" (builtins.length shellManips >= 7))
    # Backtick: must have input_source_if condition
    (assert' "karabiner: backtick has input_source_if" (builtins.any (c: c.type == "input_source_if") (backtickManip.conditions or [])))
    (assert' "karabiner: backtick to has option modifier" (builtins.any (t: builtins.elem "left_option" (t.modifiers or [])) (backtickManip.to or [])))
  ];

  # =========================================================================
  # 5. AeroSpace Output Validation
  # =========================================================================
  aerospaceOutputTests = let
    toml = keymapPipeline.aerospaceToml;
  in [
    (assert' "aerospace: contains config-version" (lib.hasInfix "config-version = 2" toml))
    (assert' "aerospace: has workspace bindings" (lib.hasInfix "ctrl-alt-shift-c = 'workspace Code'" toml))
    (assert' "aerospace: has move bindings" (lib.hasInfix "cmd-ctrl-alt-shift-c" toml))
    (assert' "aerospace: has service mode" (lib.hasInfix "[mode.service.binding]" toml))
    (assert' "aerospace: has on-window-detected" (lib.hasInfix "[[on-window-detected]]" toml))
    (assert' "aerospace: has floating rules" (lib.hasInfix "layout floating" toml))
  ];

  # =========================================================================
  # 6. MCP Adapters
  # =========================================================================
  mcpAdapterTests = let
    mockServers = {
      test-server = {
        command = "npx";
        args = ["-y" "test-mcp"];
        headers = {"X-Key" = "val";};
      };
    };
    adapted = mcpAdapt mockServers;
  in [
    (assert' "mcp-codex: has enabled flag" (adapted.codex.test-server.enabled == true))
    (assert' "mcp-codex: headers renamed to http_headers" (adapted.codex.test-server ? http_headers))
    (assert' "mcp-codex: original headers removed" (!(adapted.codex.test-server ? headers)))
    (assert' "mcp-gemini: only command+args" (adapted.gemini.test-server
      == {
        command = "npx";
        args = ["-y" "test-mcp"];
      }))
    (assert' "mcp-claude: pass-through" (adapted.claude == mockServers))
  ];

  # =========================================================================
  # 7. Zellij Config Generation
  # =========================================================================
  zellijTests = let
    darwinConfig = import ../lib/mk-zellij-config.nix {
      isDarwin = true;
    };
    linuxConfig = import ../lib/mk-zellij-config.nix {
      isDarwin = false;
    };
  in [
    (assert' "zellij-darwin: pbcopy" (lib.hasInfix ''copy_command "pbcopy"'' darwinConfig))
    (assert' "zellij-darwin: kitty protocol" (lib.hasInfix "support_kitty_keyboard_protocol true" darwinConfig))
    (assert' "zellij-linux: xclip" (lib.hasInfix ''copy_command "xclip -selection clipboard"'' linuxConfig))
    (assert' "zellij-linux: no kitty protocol" (lib.hasInfix "// support_kitty_keyboard_protocol false" linuxConfig))
    (assert' "zellij-both: has keybinds" (lib.hasInfix "keybinds clear-defaults=true" darwinConfig))
  ];

  # =========================================================================
  # 8. Spec Validation (happy + edge cases)
  # =========================================================================
  specTests = let
    validEntry = {
      bind = "ctrl+a";
      to = "cmd+a";
      tags = ["karabiner"];
    };
    shellEntry = {
      bind = "ctrl+cmd+t";
      shell = "open -a WezTerm";
      tags = ["karabiner"];
    };
    complexEntry = {
      bind = "caps_lock";
      to_if_alone = ["escape"];
      to_if_held = ["hyper"];
      tags = ["karabiner"];
    };
    validated = spec.validate [validEntry shellEntry complexEntry];
    # Edge: spec.detectType
    detectRemap = spec.detectType validEntry;
    detectShell = spec.detectType shellEntry;
    detectComplex = spec.detectType complexEntry;
  in [
    (assert' "spec: validates 3 entries" (builtins.length validated == 3))
    (assert' "spec: preserves bind" ((builtins.head validated).bind == "ctrl+a"))
    (assert' "spec: detectType remap" (detectRemap == "remap"))
    (assert' "spec: detectType shell" (detectShell == "shell"))
    (assert' "spec: detectType complex" (detectComplex == "complex"))
  ];

  # =========================================================================
  # 9. Discovery & Overlays
  # =========================================================================
  discoveryTests = let
    profiles = discoverModules ../user;
    collected = collectOverlays ../modules;
  in [
    (assert' "discover: finds limjihoon" (profiles ? limjihoon))
    (assert' "discover: profile has username" (profiles.limjihoon.username == "limjihoon"))
    (assert' "overlays: finds overlay files" (builtins.length collected > 0))
    (assert' "overlays: all are functions" (builtins.all builtins.isFunction collected))
    (assert' "overlays: expected count" (builtins.length collected == 3))
  ];

  # =========================================================================
  allTests =
    userProfileTests
    ++ platformTests
    ++ keymapStructureTests
    ++ karabinerOutputTests
    ++ aerospaceOutputTests
    ++ mcpAdapterTests
    ++ zellijTests
    ++ specTests
    ++ discoveryTests;
in {
  results = allTests;
  summary = {
    total = builtins.length allTests;
    passed = builtins.length (builtins.filter (t: t.pass) allTests);
  };
}
