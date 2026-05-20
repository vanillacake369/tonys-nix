{
  lib,
  keybinds,
}: let
  maps = builtins.filter (m: builtins.elem "karabiner" m.tags) keybinds.keymaps;

  # "cmd+ctrl+q" -> { key_code = "q"; modifiers = ["left_command" "left_control"]; }
  parseExpression = expr: let
    parts = lib.splitString "+" expr;
    rawKey = lib.last parts;
    mods = lib.init parts;
    mapMod = m:
      if m == "cmd" || m == "command"
      then "left_command"
      else if m == "ctrl" || m == "control"
      then "left_control"
      else if m == "alt" || m == "option"
      then "left_option"
      else if m == "shift"
      then "left_shift"
      else m;
    parsedMods = map mapMod mods;
  in
    {key_code = rawKey;}
    // lib.optionalAttrs (parsedMods != []) {modifiers = parsedMods;};

  # from clause: mandatory + optional modifiers
  mkFrom = m: let
    parts = lib.splitString "+" m.bind;
    rawKey = lib.last parts;
    mods = lib.init parts;
    mapMod = mod:
      if mod == "hyper"
      then ["left_control" "left_shift" "left_option"]
      else if mod == "cmd"
      then ["left_command"]
      else if mod == "ctrl"
      then ["left_control"]
      else if mod == "option" || mod == "alt"
      then ["left_option"]
      else if mod == "shift"
      then ["left_shift"]
      else [mod];
    parsedMods = lib.flatten (map mapMod mods);
  in {
    key_code = rawKey;
    modifiers =
      {mandatory = parsedMods;}
      // lib.optionalAttrs (m ? optional) {optional = m.optional;};
  };

  # to action: shell_command / key remap / disable(vk_none)
  mkTo = m:
    if m ? shell
    then [{shell_command = m.shell;}]
    else if !(m ? to)
    then null
    else if builtins.isList m.to && m.to == []
    then [{key_code = "vk_none";}]
    else if builtins.isList m.to
    then
      map (
        x:
          if builtins.isString x
          then parseExpression x
          else x
      )
      m.to
    else if builtins.isString m.to
    then [(parseExpression m.to)]
    else null;

  # complete manipulator
  mkRule = m: let
    toAction = mkTo m;
  in
    {
      type = "basic";
      from = mkFrom m;
    }
    // lib.optionalAttrs (toAction != null) {to = toAction;}
    // lib.optionalAttrs (m ? to_if_alone) {
      to_if_alone =
        map (
          x:
            if builtins.isString x
            then {key_code = x;}
            else if x ? select_input_source
            then {select_input_source = {language = x.select_input_source;};}
            else x
        )
        m.to_if_alone;
    }
    // lib.optionalAttrs (m ? to_if_held && builtins.elem "hyper" m.to_if_held) {
      to = [
        {
          set_variable = {
            name = "capslock_held";
            value = 1;
          };
        }
        {
          key_code = "left_shift";
          modifiers = ["left_control" "left_option"];
        }
      ];
      to_after_key_up = [
        {
          set_variable = {
            name = "capslock_held";
            value = 0;
          };
        }
      ];
    }
    // lib.optionalAttrs (m ? unless || m ? only || m ? condition) {
      conditions =
        (lib.optional (m ? unless) {
          type = "frontmost_application_unless";
          bundle_identifiers = m.unless;
        })
        ++ (lib.optional (m ? only) {
          type = "frontmost_application_if";
          bundle_identifiers = m.only;
        })
        ++ (lib.optional (m ? condition) (
          if m.condition.type == "variable_unless"
          then {
            type = "variable_unless";
            name = m.condition.name;
            value = m.condition.value;
          }
          else m.condition
        ));
    };
in
  builtins.toJSON {
    profiles = [
      {
        name = "Default profile";
        selected = true;
        complex_modifications = {
          parameters = {
            "basic.simultaneous_threshold_milliseconds" = 50;
            "basic.to_if_alone_timeout_milliseconds" = 250;
            "basic.to_if_held_down_threshold_milliseconds" = 500;
          };
          rules = [
            {
              description = "Nix SSOT Generated Rules";
              manipulators = map mkRule maps;
            }
          ];
        };
      }
    ];
  }
