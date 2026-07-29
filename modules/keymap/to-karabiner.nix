{
  lib,
  spec,
}: let
  cfg = spec.karabiner;

  modifierCodes = {
    cmd = "left_command";
    command = "left_command";
    ctrl = "left_control";
    control = "left_control";
    option = "left_option";
    alt = "left_option";
    shift = "left_shift";
    fn = "fn";
  };

  mapModifier = modifier:
    modifierCodes.${modifier} or modifier;

  parseExpression = expression: let
    parts = lib.splitString "+" expression;
    key = lib.last parts;
    rawModifiers = lib.init parts;
    modifiers = lib.unique (lib.flatten (map (
        modifier:
          if modifier == "caps"
          then map mapModifier cfg.caps.to_modifiers
          else [(mapModifier modifier)]
      )
      rawModifiers));
  in
    {key_code = key;}
    // lib.optionalAttrs (modifiers != []) {inherit modifiers;};

  resolveContext = name:
    if builtins.hasAttr name cfg.contexts
    then cfg.contexts.${name}
    else throw "Karabiner exporter: unknown context '${name}'";

  contextCondition = kind: name: let
    context = resolveContext name;
  in
    if context.type or null == "input_source_if"
    then context
    else {
      type =
        if kind == "only"
        then "frontmost_application_if"
        else "frontmost_application_unless";
      inherit (context) bundle_identifiers;
    };

  renderConditions = rule:
    (lib.optional (rule ? only) (contextCondition "only" rule.only))
    ++ (lib.optional (rule ? unless) (contextCondition "unless" rule.unless))
    ++ (lib.optional (rule ? condition) (resolveContext rule.condition));

  renderFrom = rule:
    if rule ? from_consumer_key
    then {
      consumer_key_code = rule.from_consumer_key;
      modifiers = {mandatory = [];};
    }
    else let
      parsed = parseExpression rule.bind;
    in {
      inherit (parsed) key_code;
      modifiers =
        {
          mandatory = parsed.modifiers or [];
        }
        // lib.optionalAttrs (rule ? optional) {
          inherit (rule) optional;
        };
    };

  renderToItem = value:
    if builtins.isString value
    then parseExpression value
    else value;

  renderTo = rule:
    if rule ? shell
    then [{shell_command = rule.shell;}]
    else if rule ? to_consumer_key
    then [
      {
        consumer_key_code = rule.to_consumer_key;
        modifiers = map mapModifier (rule.to_modifiers or []);
      }
    ]
    else if rule ? disable && rule.disable
    then [{key_code = "vk_none";}]
    else if builtins.isList rule.to
    then map renderToItem rule.to
    else [(renderToItem rule.to)];

  renderRule = rule: let
    conditions = renderConditions rule;
  in
    {
      type = "basic";
      from = renderFrom rule;
      to = renderTo rule;
    }
    // lib.optionalAttrs (conditions != []) {inherit conditions;};

  renderAlone = action:
    if builtins.isString action
    then {key_code = action;}
    else if action ? select_input_source
    then {
      select_input_source = {
        language = action.select_input_source;
      };
    }
    else action;

  capsModifiers = map mapModifier cfg.caps.to_modifiers;
  capsRule = {
    type = "basic";
    description = cfg.caps.description;
    from = {
      key_code = cfg.caps.trigger;
      modifiers = {optional = ["any"];};
    };
    to = [
      {
        key_code = lib.head capsModifiers;
        modifiers = lib.tail capsModifiers;
        lazy = true;
      }
    ];
    to_if_alone = map renderAlone cfg.caps.to_if_alone;
  };
in
  builtins.toJSON {
    profiles = [
      {
        name = "Default profile";
        selected = true;
        complex_modifications = {
          parameters = {
            "basic.simultaneous_threshold_milliseconds" =
              cfg.parameters.simultaneous_threshold_milliseconds;
            "basic.to_if_alone_timeout_milliseconds" =
              cfg.parameters.to_if_alone_timeout_milliseconds;
            "basic.to_if_held_down_threshold_milliseconds" =
              cfg.parameters.to_if_held_down_threshold_milliseconds;
          };
          rules = [
            {
              description = "Generated from binds.toml by Nix";
              manipulators = [capsRule] ++ map renderRule cfg.rules;
            }
          ];
        };
      }
    ];
  }
