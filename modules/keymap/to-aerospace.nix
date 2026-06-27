{
  lib,
  keybinds,
}: let
  ws = keybinds.workspaces;
  st = keybinds.settings;
  maps = keybinds.keymaps;

  fmtKey = key: let
    k = lib.last (lib.splitString "+" (toString key));
  in
    if k == "left_arrow"
    then "left"
    else if k == "right_arrow"
    then "right"
    else if k == "up_arrow"
    then "up"
    else if k == "down_arrow"
    then "down"
    else if k == "grave_accent_and_tilde"
    then "backtick"
    else if k == "equal_sign"
    then "equal"
    else if k == "hyphen"
    then "minus"
    else if k == "spacebar"
    then "space"
    else k;

  fmtMods = mods: let
    parsed = lib.flatten (map (
        p:
          if p == "hyper"
          then ["ctrl" "alt" "shift"]
          else if p == "cmd"
          then ["cmd"]
          else if p == "ctrl"
          then ["ctrl"]
          else if p == "option" || p == "alt"
          then ["alt"]
          else if p == "shift"
          then ["shift"]
          else []
      )
      mods);
  in
    lib.concatStringsSep "-" (lib.lists.unique parsed);

  wsNames = builtins.attrNames ws;

  baseConfig = ''
    config-version = 2
    start-at-login = true
    enable-normalization-flatten-containers = false
    enable-normalization-opposite-orientation-for-nested-containers = true
    accordion-padding = 30
    default-root-container-layout = 'tiles'
    default-root-container-orientation = 'auto'
    on-focused-monitor-changed = ['move-mouse monitor-lazy-center']
    automatically-unhide-macos-hidden-apps = false

    persistent-workspaces = [${lib.concatMapStringsSep ", " (n: "'${n}'") wsNames}]

    [key-mapping]
    preset = 'qwerty'

    [gaps]
    inner.horizontal = ${toString st.gaps.inner}
    inner.vertical =   ${toString st.gaps.inner}
    outer.left =       ${toString st.gaps.outer}
    outer.bottom =     ${toString st.gaps.outer}
    outer.top =        ${toString st.gaps.outer}
    outer.right =      ${toString st.gaps.outer}
  '';

  wsConfig = ''
    [workspace-to-monitor-force-assignment]
    ${lib.concatStringsSep "\n" (map (n: "${n} = ${toString ws.${n}.monitor}") wsNames)}
  '';

  appRules = let
    mkMoveRule = name: appId: ''
      [[on-window-detected]]
      if.app-id = '${appId}'
      run = 'move-node-to-workspace ${name}'
    '';
    mkMoveRuleRegex = name: regex: ''
      [[on-window-detected]]
      if.app-name-regex-substring = '${regex}'
      run = 'move-node-to-workspace ${name}'
    '';

    moveRules = lib.concatStringsSep "\n" (lib.flatten (map (
        n:
          map (
            app:
              if lib.hasInfix "." app
              then mkMoveRule n app
              else mkMoveRuleRegex n app
          )
          (ws.${n}.apps or [])
      )
      wsNames));

    floatingRules =
      lib.concatMapStringsSep "\n" (app: ''
        [[on-window-detected]]
        if.app-name-regex-substring = '${app}'
        run = 'layout floating'
      '')
      st.floating_apps;
  in
    moveRules + "\n" + floatingRules + "\n[[on-window-detected]]\ncheck-further-callbacks = true\nrun = 'split opposite'";

  mkBinding = m: let
    sourceParts = lib.splitString "+" m.bind;
    sourceMods = lib.init sourceParts;
    sourceKey = lib.last sourceParts;

    modsStr = fmtMods sourceMods;
    keyStr = fmtKey sourceKey;
    bindingStr =
      if modsStr == ""
      then keyStr
      else "${modsStr}-${keyStr}";

    cmds =
      if m ? exec
      then
        (
          if builtins.isList m.exec
          then m.exec
          else [m.exec]
        )
      else if m ? shell
      then ["exec-and-forget ${m.shell}"]
      else null;

    action =
      if cmds == null
      then null
      else if builtins.length cmds > 1
      then "[${lib.concatMapStringsSep ", " (x: "'${x}'") cmds}]"
      else "'${lib.head cmds}'";
  in
    if action == null
    then null
    else {
      name = bindingStr;
      value = action;
    };

  allAeroBindings = builtins.filter (m: builtins.elem "aerospace" m.tags) maps;
  processedBindings = builtins.filter (x: x != null) (map mkBinding allAeroBindings);
  uniqueBindings = builtins.listToAttrs processedBindings;

  bindingLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (n: v: "${n} = ${v}") uniqueBindings);
in ''
  ${baseConfig}
  ${wsConfig}

  [mode.main.binding]
  ${bindingLines}

  [mode.service.binding]
  esc = ['reload-config', 'mode main']
  f = ['layout floating tiling', 'mode main']
  h = ['join-with left', 'mode main']
  j = ['join-with down', 'mode main']
  k = ['join-with up', 'mode main']
  l = ['join-with right', 'mode main']

  ${appRules}
''
