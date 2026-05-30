# Guard tests: core invariants only (discovery, SSoT data, pure mappers).
# Detailed output-format / platform / policy-internal tests were intentionally
# dropped — build-time assertions + `nix flake check` + per-platform builds
# cover the rest. Keep this file small so the structure stays flexible.
# Run: nix eval .#tests.summary --json
# Run verbose: nix eval .#tests.results --json | python3 -m json.tool
{lib}: let
  # --- Fixtures ---
  userProfile = import ../user/limjihoon.nix;
  keybinds = import ../modules/keymap/binds.nix {inherit lib userProfile;};
  mcpAdapt = import ../modules/agents/mcp-adapters.nix {inherit lib;};
  collectOverlays = import ../lib/collect-overlays.nix {inherit lib;};
  discoverModules = import ../lib/discover-modules.nix {inherit lib;};

  # --- Assertion helper ---
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else builtins.throw "FAIL: ${name}";

  # =========================================================================
  # 1. Overlay discovery (*.overlay.nix convention)
  # =========================================================================
  overlayTests = let
    collected = collectOverlays ../modules;
  in [
    (assert' "overlays: finds overlay files" (builtins.length collected > 0))
    (assert' "overlays: all are functions" (builtins.all builtins.isFunction collected))
    (assert' "overlays: expected count" (builtins.length collected == 3))
  ];

  # =========================================================================
  # 2. Domain-module discovery (*.hm.nix / *.nixos.nix convention)
  # =========================================================================
  entrypointTests = let
    discovered = discoverModules ../modules;
  in [
    (assert' "discover: home-manager entrypoints is a list" (builtins.isList discovered.homeManager))
    (assert' "discover: 5+ home-manager entrypoints" (builtins.length discovered.homeManager >= 5))
    (assert' "discover: all hm end with .hm.nix" (
      builtins.all (p: lib.hasSuffix ".hm.nix" (toString p)) discovered.homeManager
    ))
    (assert' "discover: nixos entrypoints is a list" (builtins.isList discovered.nixos))
    (assert' "discover: 8+ nixos entrypoints" (builtins.length discovered.nixos >= 8))
    (assert' "discover: all nixos end with .nixos.nix" (
      builtins.all (p: lib.hasSuffix ".nixos.nix" (toString p)) discovered.nixos
    ))
  ];

  # =========================================================================
  # 3. Keymap SSoT data integrity
  # =========================================================================
  keymapTests = let
    karabinerMaps = builtins.filter (m: builtins.elem "karabiner" m.tags) keybinds.keymaps;
    aerospaceMaps = builtins.filter (m: builtins.elem "aerospace" m.tags) keybinds.keymaps;
  in [
    (assert' "keymaps: has entries" (builtins.length keybinds.keymaps > 0))
    (assert' "keymaps: karabiner maps" (builtins.length karabinerMaps > 0))
    (assert' "keymaps: aerospace maps" (builtins.length aerospaceMaps > 0))
    (assert' "keymaps: 6+ workspaces" (builtins.length (builtins.attrNames keybinds.workspaces) >= 6))
    (assert' "keymaps: browsers from userProfile" (builtins.any (m: m ? only && m.only == userProfile.browsers.bundleIds) karabinerMaps))
    (assert' "keymaps: jetbrains bundleIds from userProfile" (keybinds.workspaces.Code.apps == userProfile.jetbrains.bundleIds))
  ];

  # =========================================================================
  # 4. MCP adapters (pure SSoT → per-provider shape)
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
  # 5. Zellij config generation (platform-conditional)
  # =========================================================================
  zellijTests = let
    darwinConfig = import ../lib/mk-zellij-config.nix {isDarwin = true;};
    linuxConfig = import ../lib/mk-zellij-config.nix {isDarwin = false;};
  in [
    (assert' "zellij-darwin: pbcopy" (lib.hasInfix ''copy_command "pbcopy"'' darwinConfig))
    (assert' "zellij-darwin: kitty protocol" (lib.hasInfix "support_kitty_keyboard_protocol true" darwinConfig))
    (assert' "zellij-linux: xclip" (lib.hasInfix ''copy_command "xclip -selection clipboard"'' linuxConfig))
    (assert' "zellij-both: has keybinds" (lib.hasInfix "keybinds clear-defaults=true" darwinConfig))
  ];

  # =========================================================================
  allTests =
    overlayTests
    ++ entrypointTests
    ++ keymapTests
    ++ mcpAdapterTests
    ++ zellijTests;
in {
  results = allTests;
  summary = {
    total = builtins.length allTests;
    passed = builtins.length (builtins.filter (t: t.pass) allTests);
  };
}
