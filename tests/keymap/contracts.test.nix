{lib}: let
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  keymapDsl = builtins.readFile ../../modules/keymap/binds.toml;
  keymapModule = builtins.readFile ../../modules/keymap/keymap.hm.nix;
  spec = builtins.fromTOML keymapDsl;

  aerospaceToml = import ../../modules/keymap/to-aerospace.nix {
    inherit lib spec;
  };
  karabinerJson = builtins.fromJSON (import ../../modules/keymap/to-karabiner.nix {
    inherit lib spec;
  });
  karabinerManipulators =
    (builtins.head (builtins.head karabinerJson.profiles).complex_modifications.rules).manipulators;

  hasAeroBinding = line: lib.hasInfix line aerospaceToml;

  hasKoreanInputSourceCondition = conditions:
    builtins.any (
      c:
        c.type
        == "input_source_if"
        && builtins.any (s: s ? language && s.language == "ko") c.input_sources
        && builtins.any (
          s: s ? input_source_id && s.input_source_id == "^com\\.apple\\.inputmethod\\.Korean$"
        )
        c.input_sources
        && builtins.any (
          s: s ? input_mode_id && s.input_mode_id == "^com\\.apple\\.inputmethod\\.Korean\\..*$"
        )
        c.input_sources
    )
    conditions;

  hasKarabinerMap = keyCode: mandatory: toValue:
    builtins.any (
      m:
        (m.from.key_code or null)
        == keyCode
        && (m.from.modifiers.mandatory or []) == mandatory
        && m.to == [toValue]
    )
    karabinerManipulators;

  hasConsumerMap = consumerKey:
    builtins.any (
      m:
        (m.from.consumer_key_code or null)
        == consumerKey
        && m.to
        == [
          {
            consumer_key_code = consumerKey;
            modifiers = ["left_option" "left_shift"];
          }
        ]
    )
    karabinerManipulators;

  hasFnConsumerMap = keyCode: consumerKey:
    builtins.any (
      m:
        (m.from.key_code or null)
        == keyCode
        && (m.from.modifiers.mandatory or []) == ["fn"]
        && m.to
        == [
          {
            consumer_key_code = consumerKey;
            modifiers = ["left_option" "left_shift"];
          }
        ]
    )
    karabinerManipulators;

  hasAppCondition = kind: bundle: m:
    builtins.any (
      c:
        c.type
        == kind
        && builtins.elem bundle c.bundle_identifiers
    )
    (m.conditions or []);

  findKarabinerFrom = keyCode: mandatory:
    builtins.filter (
      m:
        (m.from.key_code or null)
        == keyCode
        && (m.from.modifiers.mandatory or []) == mandatory
    )
    karabinerManipulators;
in {
  results = [
    (assert' "keymaps: TOML DSL is the SSoT" (
      builtins.pathExists ../../modules/keymap/binds.toml
      && !(builtins.pathExists ../../modules/keymap/binds.nix)
      && !(builtins.pathExists ../../modules/keymap/pipeline.nix)
      && !(builtins.pathExists ../../modules/keymap/binds.generated.json)
      && lib.hasInfix "[aerospace.settings]" keymapDsl
      && lib.hasInfix "[karabiner.caps]" keymapDsl
      && lib.hasInfix "builtins.fromTOML" keymapModule
    ))
    (assert' "keymaps: AeroSpace workspace policy is explicit" (
      spec.aerospace.settings.persistent_workspaces
      == ["Docs" "Code" "Browser" "Terminal" "Music" "Schedule"]
      && builtins.length spec.aerospace.workspace_assignments == 6
      && builtins.all (entry: builtins.elem entry.workspace spec.aerospace.settings.persistent_workspaces) spec.aerospace.workspace_assignments
    ))
    (assert' "keymaps: AeroSpace exporter renders workspace and monitor bindings" (
      hasAeroBinding "ctrl-alt-c = 'workspace Code'"
      && hasAeroBinding "ctrl-alt-shift-c = ['move-node-to-workspace Code', 'workspace Code']"
      && hasAeroBinding "ctrl-alt-1 = 'focus-monitor 1'"
      && hasAeroBinding "ctrl-alt-shift-1 = ['move-node-to-monitor 1', 'focus-monitor 1']"
      && hasAeroBinding "ctrl-alt-tab = 'workspace-back-and-forth'"
      && hasAeroBinding "ctrl-alt-period = 'mode service'"
    ))
    (assert' "keymaps: AeroSpace exporter renders service mode bindings" (
      hasAeroBinding "[mode.service.binding]"
      && hasAeroBinding "esc = ['reload-config', 'mode main']"
      && hasAeroBinding "f = ['layout floating tiling', 'mode main']"
      && hasAeroBinding "h = ['join-with left', 'mode main']"
    ))
    (assert' "keymaps: Karabiner Caps alone sends Escape and English input" (
      let
        capsRule = builtins.head karabinerManipulators;
      in
        capsRule.from.key_code
        == "caps_lock"
        && capsRule.to
        == [
          {
            key_code = "left_control";
            modifiers = ["left_option"];
            lazy = true;
          }
        ]
        && capsRule.to_if_alone
        == [
          {key_code = "escape";}
          {select_input_source = {language = "en";};}
        ]
    ))
    (assert' "keymaps: Karabiner Caps navigation emits native arrows" (
      hasKarabinerMap "h" ["left_control" "left_option"] {key_code = "left_arrow";}
      && hasKarabinerMap "j" ["left_control" "left_option"] {key_code = "down_arrow";}
      && hasKarabinerMap "k" ["left_control" "left_option"] {key_code = "up_arrow";}
      && hasKarabinerMap "l" ["left_control" "left_option"] {key_code = "right_arrow";}
    ))
    (assert' "keymaps: Karabiner Caps shift navigation emits selection arrows" (
      hasKarabinerMap "h" ["left_control" "left_option" "left_shift"] {
        key_code = "left_arrow";
        modifiers = ["left_shift"];
      }
      && hasKarabinerMap "l" ["left_control" "left_option" "left_shift"] {
        key_code = "right_arrow";
        modifiers = ["left_shift"];
      }
    ))
    (assert' "keymaps: Korean backtick and tilde rules target Apple Korean input sources" (
      let
        graveRules = findKarabinerFrom "grave_accent_and_tilde" [];
        tildeRules = findKarabinerFrom "grave_accent_and_tilde" ["left_shift"];
      in
        builtins.any (m:
          m.to
          == [
            {
              key_code = "grave_accent_and_tilde";
              modifiers = ["left_option"];
            }
          ]
          && hasKoreanInputSourceCondition m.conditions)
        graveRules
        && builtins.any (m:
          m.to
          == [
            {
              key_code = "grave_accent_and_tilde";
              modifiers = ["left_shift" "left_option"];
            }
          ]
          && hasKoreanInputSourceCondition m.conditions)
        tildeRules
    ))
    (assert' "keymaps: fine brightness and volume steps are preserved" (
      hasConsumerMap "display_brightness_decrement"
      && hasConsumerMap "display_brightness_increment"
      && hasFnConsumerMap "f1" "display_brightness_decrement"
      && hasFnConsumerMap "f2" "display_brightness_increment"
      && hasConsumerMap "volume_decrement"
      && hasConsumerMap "volume_increment"
      && hasFnConsumerMap "f11" "volume_decrement"
      && hasFnConsumerMap "f12" "volume_increment"
    ))
    (assert' "keymaps: terminal and browser conditions stay scoped" (
      let
        ctrlA = builtins.head (findKarabinerFrom "a" ["left_control"]);
        cmdE = builtins.head (findKarabinerFrom "e" ["left_command"]);
      in
        hasAppCondition "frontmost_application_unless" "^com\\.github\\.wez\\.wezterm$" ctrlA
        && hasAppCondition "frontmost_application_if" "^com\\.google\\.Chrome$" cmdE
    ))
    (assert' "keymaps: generated files remain outside the repo" (
      !(lib.hasInfix "binds.generated.json" keymapModule)
      && !(lib.hasInfix "binds.generated.json" aerospaceToml)
    ))
  ];
}
