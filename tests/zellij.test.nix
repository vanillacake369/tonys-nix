{lib}: let
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  darwinConfig = import ../lib/mk-zellij-config.nix {isDarwin = true;};
  linuxConfig = import ../lib/mk-zellij-config.nix {isDarwin = false;};
  managedConfig = import ../lib/mk-zellij-config.nix {
    isDarwin = true;
    fishPath = "/nix/store/test-fish/bin/fish";
    pluginDir = "/Users/test/.config/zellij/plugins";
  };
  zellijModule = builtins.readFile ../modules/shell/zellij.hm.nix;
  panePicker = builtins.readFile ../dotfiles/zellij/scripts/zellij-pane-picker;
  contextToggle = builtins.readFile ../dotfiles/zellij/scripts/zellij-context-toggle;
  navLib = builtins.readFile ../dotfiles/zellij/scripts/zellij-nav-lib;
  navDispatch = builtins.readFile ../dotfiles/zellij/scripts/zellij-nav-dispatch;

  directSection =
    builtins.elemAt
    (builtins.split ''shared_except "locked" "scroll" "search" "entersearch" "renametab" "renamepane" \{'' darwinConfig)
    2;
  directSectionBody =
    builtins.elemAt (builtins.split ''
      shared_except''
    directSection)
    0;
in {
  results = [
    (assert' "zellij-config: platform clipboard and deterministic paths" (
      lib.hasInfix ''copy_command "pbcopy"'' darwinConfig
      && lib.hasInfix ''copy_command "xclip -selection clipboard"'' linuxConfig
      && lib.hasInfix ''default_shell "/nix/store/test-fish/bin/fish"'' managedConfig
      && lib.hasInfix ''file:/Users/test/.config/zellij/plugins/zellij-forgot.wasm'' managedConfig
    ))
    (assert' "zellij-config: core keyboard policy is stable" (
      lib.hasInfix "support_kitty_keyboard_protocol true" darwinConfig
      && lib.hasInfix ''fish_features "no-query-term"'' darwinConfig
      && lib.hasInfix ''fish_features "no-query-term"'' linuxConfig
      && lib.hasInfix "keybinds clear-defaults=true" darwinConfig
      && lib.hasInfix ''bind "Ctrl g" { SwitchToMode "locked"; }'' darwinConfig
      && lib.hasInfix ''
        locked {
                bind "Ctrl g" { SwitchToMode "normal"; }''
      darwinConfig
    ))
    (assert' "zellij-config: direct shortcuts exclude locked and text-input modes" (
      builtins.all (binding: lib.hasInfix binding directSectionBody) [
        ''bind "Alt p" { SwitchToMode "pane"; }''
        ''bind "Alt Shift p"''
        ''zellij-pane-picker --panes''
        ''bind "Alt t" { SwitchToMode "tab"; }''
        ''bind "Alt Shift t"''
        ''zellij-pane-picker --tabs''
        ''bind "Alt s" { SwitchToMode "session"; }''
        ''bind "Alt Shift s"''
        ''ZELLIJ_NAV_HELPER=1 exec ~/.config/zellij/scripts/zellij-pane-picker --sessions''
        ''bind "Alt Space"''
        ''zellij-pane-picker --all''
        ''bind "Alt /"''
        ''LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-forgot.wasm"''
        ''bind "Alt [" { PreviousSwapLayout; }''
        ''bind "Alt ]" { NextSwapLayout; }''
        ''bind "Alt N" { FocusPreviousPane; }''
        ''bind "Alt n"''
        ''ZELLIJ_NAV_HELPER=1 ZELLIJ_NAV_FOCUS_UNDERLYING=1 exec ~/.config/zellij/scripts/zellij-context-toggle''
        ''bind "Alt r" { SwitchToMode "resize"; }''
        ''bind "Alt m" { SwitchToMode "move"; }''
        ''bind "Alt e" { SwitchToMode "scroll"; }''
        ''bind "Alt h" { MoveFocusOrTab "left"; }''
        ''bind "Alt j" { MoveFocus "down"; }''
        ''bind "Alt k" { MoveFocus "up"; }''
        ''bind "Alt l" { MoveFocusOrTab "right"; }''
        ''bind "Alt f" { ToggleFocusFullscreen; }''
        ''bind "Alt w" { ToggleFloatingPanes; }''
      ]
      && !(lib.hasInfix ''bind "Alt 6"'' darwinConfig)
      && !(lib.hasInfix ''bind "Alt g"'' darwinConfig)
    ))
    (assert' "zellij-config: removed custom leader and layout wiring" (
      !(lib.hasInfix "zellij-autolock" darwinConfig)
      && !(lib.hasInfix ''bind "Alt z"'' darwinConfig)
      && !(lib.hasInfix ''SwitchToMode "tmux"'' darwinConfig)
      && !(builtins.pathExists ../dotfiles/zellij/layouts/default.kdl)
      && !(builtins.pathExists ../dotfiles/zellij/layouts/minimal.kdl)
      && !(lib.hasInfix ''.config/zellij/layouts/default.kdl'' zellijModule)
      && !(lib.hasInfix ''.config/zellij/layouts/minimal.kdl'' zellijModule)
      && !(lib.hasInfix "zjstatus" zellijModule)
      && !(lib.hasInfix "zjstatus" darwinConfig)
      && lib.hasInfix ''default_layout "compact"'' darwinConfig
    ))
    (assert' "zellij-picker: uses json actions and live previews" (
      lib.hasInfix "zellij action list-panes --json" panePicker
      && lib.hasInfix "zellij action list-tabs --json" panePicker
      && lib.hasInfix "--render-preview" panePicker
      && lib.hasInfix "action dump-screen --pane-id" panePicker
      && lib.hasInfix "cmp -s" panePicker
      && lib.hasInfix "mktemp" panePicker
      && lib.hasInfix "ZELLIJ_PICKER_PREVIEW_LIVE_DELAY" panePicker
      && lib.hasInfix "ZELLIJ_PICKER_PREVIEW_INTERVAL" panePicker
      && lib.hasInfix "right,65%,border-left,noinfo" panePicker
      && !(lib.hasInfix "right,65%,border-left,follow,noinfo" panePicker)
    ))
    (assert' "zellij-navigation: helper exits before deferred target switch" (
      lib.hasInfix "ZELLIJ_NAV_HELPER" panePicker
      && lib.hasInfix "close_helper_pane_on_exit" panePicker
      && lib.hasInfix "trap close_helper_pane_on_exit EXIT" panePicker
      && lib.hasInfix "nav_defer_navigation_to_target" panePicker
      && lib.hasInfix "ZELLIJ_NAV_HELPER" contextToggle
      && lib.hasInfix "nav_defer_context_toggle" contextToggle
      && lib.hasInfix "trap close_helper_pane_on_exit EXIT" contextToggle
      && lib.hasInfix "action close-pane --pane-id" navLib
      && lib.hasInfix "zellij-nav-dispatch" navLib
      && lib.hasInfix "sleep \"$delay\"" navDispatch
      && lib.hasInfix "nav_navigate_to_target" navDispatch
      && lib.hasInfix ''.config/zellij/scripts/zellij-nav-dispatch'' zellijModule
    ))
    (assert' "zellij-navigation: cross-session switch stays inside current client" (
      !(lib.hasInfix ''.config/zellij/scripts/zellij-external-nav'' zellijModule)
      && !(lib.hasInfix ''zellij-external-nav'' darwinConfig)
      && !(lib.hasInfix ''ZELLIJ_NAV_EXTERNAL'' panePicker)
      && !(lib.hasInfix ''nav_target_requires_external_client'' panePicker)
      && !(lib.hasInfix ''zellij attach "$session"'' navLib)
      && lib.hasInfix ''zellij action switch-session "$session"'' navLib
      && lib.hasInfix ''zellij action switch-session "$session" --pane-id "terminal_$pane_id"'' navLib
    ))
    (assert' "zellij-navigation: helper keybinds opt in explicitly" (
      lib.hasInfix ''Run "sh" "-lc" "ZELLIJ_NAV_HELPER=1 exec ~/.config/zellij/scripts/zellij-pane-picker --sessions"'' darwinConfig
      && lib.hasInfix ''ZELLIJ_NAV_HELPER=1 ZELLIJ_NAV_FOCUS_UNDERLYING=1 exec ~/.config/zellij/scripts/zellij-context-toggle'' darwinConfig
      && lib.hasInfix ''        Run "sh" "-lc" "ZELLIJ_NAV_HELPER=1 exec ~/.config/zellij/scripts/zellij-pane-picker --sessions" {
                        floating true
                        close_on_exit true''
      darwinConfig
      && lib.hasInfix ''        Run "sh" "-lc" "ZELLIJ_NAV_HELPER=1 ZELLIJ_NAV_FOCUS_UNDERLYING=1 exec ~/.config/zellij/scripts/zellij-context-toggle" {
                        floating true
                        close_on_exit true''
      darwinConfig
      && lib.hasInfix ''        Run "sh" "-lc" "ZELLIJ_NAV_HELPER=1 exec ~/.config/zellij/scripts/zellij-pane-picker --panes" {
                        floating true
                        close_on_exit true''
      darwinConfig
      && lib.hasInfix ''        Run "sh" "-lc" "ZELLIJ_NAV_HELPER=1 exec ~/.config/zellij/scripts/zellij-pane-picker --tabs" {
                        floating true
                        close_on_exit true''
      darwinConfig
      && lib.hasInfix ''        Run "sh" "-lc" "ZELLIJ_NAV_HELPER=1 exec ~/.config/zellij/scripts/zellij-pane-picker --all" {
                        floating true
                        close_on_exit true''
      darwinConfig
    ))
  ];
}
