{lib}: let
  assert' = name: cond:
    if cond
    then {
      inherit name;
      pass = true;
    }
    else throw "FAIL: ${name}";

  darwinConfig = import ../../lib/mk-zellij-config.nix {isDarwin = true;};
  linuxConfig = import ../../lib/mk-zellij-config.nix {isDarwin = false;};
  managedConfig = import ../../lib/mk-zellij-config.nix {
    isDarwin = true;
    fishPath = "/nix/store/test-fish/bin/fish";
    pluginDir = "/Users/test/.config/zellij/plugins";
  };
  zellijModule = builtins.readFile ../../modules/shell/zellij.hm.nix;
  zellijOverlay = builtins.readFile ../../modules/shell/zellij.overlay.nix;
  panePicker = builtins.readFile ../../dotfiles/zellij/scripts/zellij-pane-picker;
  contextToggle = builtins.readFile ../../dotfiles/zellij/scripts/zellij-context-toggle;
  diagnoseContext = builtins.readFile ../../dotfiles/zellij/scripts/zellij-nav-diagnose-context;
  navSidecar = builtins.readFile ../../dotfiles/zellij/scripts/zellij-nav-sidecar;
  navPluginSwitch = builtins.readFile ../../dotfiles/zellij/scripts/zellij-nav-plugin-switch;
  navRustCargo = builtins.readFile ../../dotfiles/zellij/nav/Cargo.toml;
  navRustCli = builtins.readFile ../../dotfiles/zellij/nav/src/cli.rs;
  navRustMain = builtins.readFile ../../dotfiles/zellij/nav/src/main.rs;
  navRustContextToggle = builtins.readFile ../../dotfiles/zellij/nav/src/feature/context_toggle.rs;
  navRustDiagnose = builtins.readFile ../../dotfiles/zellij/nav/src/feature/diagnose.rs;
  navRustHelper = builtins.readFile ../../dotfiles/zellij/nav/src/feature/helper.rs;
  navRustNavigate = builtins.readFile ../../dotfiles/zellij/nav/src/feature/navigate.rs;
  navRustOutbound = builtins.readFile ../../dotfiles/zellij/nav/src/outbound/mod.rs;
  navRustPicker = builtins.readFile ../../dotfiles/zellij/nav/src/feature/picker.rs;
  navRustPluginSwitch = builtins.readFile ../../dotfiles/zellij/nav/src/feature/plugin_switch.rs;
  navRustRecordCurrent = builtins.readFile ../../dotfiles/zellij/nav/src/feature/record_current.rs;
  navRustSidecar = builtins.readFile ../../dotfiles/zellij/nav/src/feature/sidecar.rs;
  navRustToggle = builtins.readFile ../../dotfiles/zellij/nav/src/feature/toggle.rs;
  navPluginCargo = builtins.readFile ../../dotfiles/zellij/nav/wasm/switcher/Cargo.toml;
  navPluginRust = builtins.readFile ../../dotfiles/zellij/nav/wasm/switcher/src/lib.rs;
  navPluginMetadata = builtins.fromTOML (builtins.readFile ../../dotfiles/zellij/nav/wasm/switcher/zellij-plugin.toml);
  zellijConfigBase = builtins.readFile ../../dotfiles/zellij/config.kdl.base;
  zellijReadme = builtins.readFile ../../dotfiles/zellij/README.md;

  directSection =
    builtins.elemAt
    (builtins.split ''shared_except "locked" "scroll" "search" "entersearch" "renametab" "renamepane" \{'' darwinConfig)
    2;
  directSectionBody =
    builtins.elemAt (builtins.split ''
      shared_except''
    directSection)
    0;

  thinWrapper = command: file:
    lib.hasInfix ''ZELLIJ_NAV_COMMAND:-$script_dir/zellij-nav'' file
    && lib.hasInfix command file
    && !(lib.hasInfix ''zellij action list-panes --json'' file)
    && !(lib.hasInfix ''nav_init'' file)
    && !(lib.hasInfix ''nav_focus'' file)
    && !(lib.hasInfix ''nav_navigate'' file)
    && !(lib.hasInfix ''nav_record'' file)
    && !(lib.hasInfix ''jq'' file)
    && !(lib.hasInfix ''awk'' file);
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
    ))
    (assert' "zellij-config: zellij 0.45 keybindings are explicit under cleared defaults" (
      builtins.all (binding: lib.hasInfix binding darwinConfig) [
        ''bind "Shift f" { ToggleFocusNoUiFullscreen; SwitchToMode "normal"; }''
        ''bind "Shift s" { NewPane "stacked"; SwitchToMode "normal"; }''
        ''bind "[" { FocusGuestSession; SwitchToMode "normal"; }''
        ''bind "]" { FocusHostSession; SwitchToMode "normal"; }''
        ''bind "f" { ToggleHostFullscreen; SwitchToMode "normal"; }''
        ''bind "[" { ScrollToPreviousPrompt; }''
        ''bind "]" { ScrollToNextPrompt; }''
        ''bind "m" { SelectCommandAtScrollPosition; }''
        ''bind "c" { CopyLastCommandOutput; SwitchToMode "normal"; }''
      ]
    ))
    (assert' "zellij-config: direct shortcuts route to navigation entrypoints" (
      builtins.all (binding: lib.hasInfix binding directSectionBody) [
        ''zellij-pane-picker --panes''
        ''zellij-pane-picker --tabs''
        ''ZELLIJ_NAV_HELPER=1 ZELLIJ_NAV_PROTECTED_STRATEGY=plugin exec ~/.config/zellij/scripts/zellij-pane-picker --sessions''
        ''zellij-pane-picker --all''
        ''ZELLIJ_NAV_HELPER=1 ZELLIJ_NAV_PROTECTED_STRATEGY=plugin-sidecar ZELLIJ_NAV_FOCUS_UNDERLYING=1 exec ~/.config/zellij/scripts/zellij-context-toggle''
        ''LaunchOrFocusPlugin "file:~/.config/zellij/plugins/zellij-forgot.wasm"''
        ''skip_plugin_cache true''
      ]
      && !(lib.hasInfix ''bind "Alt 6"'' darwinConfig)
      && !(lib.hasInfix ''bind "Alt g"'' directSectionBody)
    ))
    (assert' "zellij-config: picker shortcuts opt into protected plugin routing" (
      lib.count
      (command: command == ''ZELLIJ_NAV_PROTECTED_STRATEGY=plugin'')
      (lib.splitString " " directSectionBody)
      >= 4
      && lib.hasInfix ''ZELLIJ_NAV_PROTECTED_STRATEGY=plugin-sidecar ZELLIJ_NAV_FOCUS_UNDERLYING=1 exec ~/.config/zellij/scripts/zellij-context-toggle'' directSectionBody
    ))
    (assert' "zellij-config: forgot plugin entries are generated from plugin metadata" (
      navPluginMetadata.forgot
      == [
        {
          label = "Plugin / zellij-nav-switcher";
          keys = "Alt Space, Alt Shift P/T/S";
        }
        {
          label = "Session / Repo picker";
          keys = "zr";
        }
        {
          label = "Session / Reload projects";
          keys = "Alt s, r";
        }
      ]
      && lib.hasInfix ''"Plugin / zellij-nav-switcher" "Alt Space, Alt Shift P/T/S"'' managedConfig
      && lib.hasInfix ''"Session / Repo picker" "zr"'' managedConfig
      && lib.hasInfix ''"Session / Reload projects" "Alt s, r"'' managedConfig
      && lib.hasInfix ''exec ~/.config/zellij/scripts/zellij-nav reload-projects'' managedConfig
      && lib.hasInfix ''close_on_exit true'' zellijConfigBase
      && !(lib.hasInfix ''"Plugin / zellij-nav-switcher" "Alt Space, Alt Shift P/T/S"'' zellijConfigBase)
      && !(lib.hasInfix ''"Session / Repo picker" "Alt g, zr"'' zellijConfigBase)
      && lib.hasInfix ''# @ZELLIJ_FORGOT_PLUGIN_ENTRIES@'' zellijConfigBase
    ))
    (assert' "zellij-config: forgot plugin includes zellij 0.45 keymap reminders" (
      builtins.all (entry: lib.hasInfix entry managedConfig) [
        ''"Pane Mode / New stacked pane" "p -> Shift s"''
        ''"Pane Mode / Toggle no-UI fullscreen" "p -> Shift f"''
        ''"Move Mode / Move pane left" "m -> h, m -> Left"''
        ''"Move Mode / Move pane right" "m -> l, m -> Right"''
        ''"Move Mode / Move pane next" "m -> n, m -> Tab"''
        ''"Move Mode / Move pane previous" "m -> p"''
        ''"Tab Mode / Break pane to new tab" "t -> b"''
        ''"Tab Mode / Break pane left" "t -> ["''
        ''"Tab Mode / Break pane right" "t -> ]"''
        ''"Scroll Mode / Previous prompt" "e -> ["''
        ''"Scroll Mode / Next prompt" "e -> ]"''
        ''"Scroll Mode / Select command" "e -> m"''
        ''"Scroll Mode / Copy last command output" "e -> c"''
        ''"Session Mode / Focus guest session" "s -> ["''
        ''"Session Mode / Focus host session" "s -> ]"''
        ''"Session Mode / Toggle host fullscreen" "s -> f"''
      ]
    ))
    (assert' "zellij-config: removed custom leader and layout wiring" (
      !(lib.hasInfix "zellij-autolock" darwinConfig)
      && !(lib.hasInfix ''bind "Alt z"'' darwinConfig)
      && !(lib.hasInfix ''SwitchToMode "tmux"'' darwinConfig)
      && !(builtins.pathExists ../../dotfiles/zellij/layouts/default.kdl)
      && !(builtins.pathExists ../../dotfiles/zellij/layouts/minimal.kdl)
      && !(lib.hasInfix "zjstatus" zellijModule)
      && !(lib.hasInfix "zjstatus" darwinConfig)
      && lib.hasInfix ''default_layout "compact"'' darwinConfig
    ))
    (assert' "zellij-navigation: runtime scripts are rust binary aliases" (
      lib.hasInfix ''.config/zellij/scripts/zellij-pane-picker'' zellijModule
      && lib.hasInfix ''.config/zellij/scripts/zellij-context-toggle'' zellijModule
      && lib.hasInfix ''.config/zellij/scripts/zellij-nav-sidecar'' zellijModule
      && lib.hasInfix ''.config/zellij/scripts/zellij-nav-plugin-switch'' zellijModule
      && lib.hasInfix ''source = "''${pkgs.zellij-nav}/bin/zellij-nav";'' zellijModule
      && !(lib.hasInfix ''.config/zellij/scripts/zellij-nav-lib'' zellijModule)
      && !(builtins.pathExists ../../dotfiles/zellij/scripts/zellij-nav-lib)
      && !(lib.hasInfix ''.config/zellij/scripts/zellij-nav-dispatch'' zellijModule)
    ))
    (assert' "zellij-navigation: local script shims are thin rust entrypoints" (
      thinWrapper ''picker-run'' panePicker
      && lib.hasInfix ''picker-preview "$@"'' panePicker
      && lib.hasInfix ''picker-command session-manager'' panePicker
      && thinWrapper ''context-toggle-run'' contextToggle
      && thinWrapper ''diagnose'' diagnoseContext
      && thinWrapper ''plugin-switch'' navPluginSwitch
      && thinWrapper ''sidecar-run'' navSidecar
    ))
    (assert' "zellij-navigation: rust feature surfaces cover main workflows" (
      lib.hasInfix ''name = "zellij-nav"'' navRustCargo
      && lib.hasInfix ''mod cli;'' navRustMain
      && lib.hasInfix ''Some("context-toggle-run")'' navRustCli
      && lib.hasInfix ''Some("picker-run")'' navRustCli
      && lib.hasInfix ''Some("picker-preview")'' navRustCli
      && lib.hasInfix ''Some("picker-command")'' navRustCli
      && lib.hasInfix ''Some("navigate")'' navRustCli
      && lib.hasInfix ''Some("record-current")'' navRustCli
      && lib.hasInfix ''Some("diagnose")'' navRustCli
      && lib.hasInfix ''Some("plugin-switch")'' navRustCli
      && lib.hasInfix ''Some("sidecar-run")'' navRustCli
      && lib.hasInfix ''Some("auto-project")'' navRustCli
      && lib.hasInfix ''Some("reload-projects")'' navRustCli
      && lib.hasInfix ''zellij-pane-picker'' navRustCli
      && lib.hasInfix ''zellij-context-toggle'' navRustCli
      && lib.hasInfix ''zellij-nav-plugin-switch'' navRustCli
      && lib.hasInfix ''zellij-nav-sidecar'' navRustCli
      && lib.hasInfix ''pub trait ContextTogglePort'' navRustContextToggle
      && lib.hasInfix ''pub trait PickerPort'' navRustPicker
      && lib.hasInfix ''pub trait HelperPort'' navRustHelper
      && lib.hasInfix ''pub trait NavigatePort'' navRustNavigate
      && lib.hasInfix ''pub trait DiagnosePort'' navRustDiagnose
      && lib.hasInfix ''pub trait PluginSwitchPort'' navRustPluginSwitch
      && lib.hasInfix ''pub trait RecordPort'' navRustRecordCurrent
      && lib.hasInfix ''pub trait SidecarPort'' navRustSidecar
      && lib.hasInfix ''pub trait TogglePort'' navRustToggle
    ))
    (assert' "zellij-navigation: protected and sidecar policies are rust-owned" (
      lib.hasInfix ''ZELLIJ_NAV_PROTECTED_COMMAND_PATTERN'' navRustOutbound
      && lib.hasInfix ''ZELLIJ_NAV_PROTECTED_STRATEGY'' navRustOutbound
      && lib.hasInfix ''protected context blocked reason=no-client-scoped-zellij-mutation strategy=block'' navRustOutbound
      && lib.hasInfix ''protected context detected route=plugin'' navRustOutbound
      && lib.hasInfix ''protected context detected route=sidecar'' navRustOutbound
      && lib.hasInfix ''pub struct WaitPolicy'' navRustSidecar
      && lib.hasInfix ''pub struct LaunchRequest'' navRustSidecar
      && lib.hasInfix ''pub fn launch'' navRustSidecar
      && lib.hasInfix ''wait_attached_requires_consecutive_counts_above_initial'' navRustSidecar
      && lib.hasInfix ''launch_uses_cli_spawn_before_start_route'' navRustSidecar
    ))
    (assert' "GIVEN zellij hm WHEN plugins are installed THEN wasm switcher is wired from package output" (
      lib.hasInfix ''.config/zellij/plugins/zellij-nav-switcher.wasm'' zellijModule
      && lib.hasInfix ''.config/zellij/project-layouts.json'' zellijModule
      && lib.hasInfix ''.config/zellij/project-roots.json'' zellijModule
      && lib.hasInfix ''projectLayouts = {};'' zellijModule
      && lib.hasInfix ''home.activation.zellijNavSwitcherPermissions'' zellijModule
      && lib.hasInfix ''pkgs.zellij-nav'' zellijModule
      && lib.hasInfix ''pkgs.zellij-room-wasm'' zellijModule
    ))
    (assert' "GIVEN zellij overlay WHEN wasm package is built THEN rust toolchain target is declared" (
      lib.hasInfix ''prev.rust-bin.stable.latest.default.override'' zellijOverlay
      && lib.hasInfix ''targets = ["wasm32-wasip1"]'' zellijOverlay
      && lib.hasInfix ''zellijWasmRustPlatform.buildRustPackage'' zellijOverlay
    ))
    (assert' "GIVEN zellij overlay WHEN rust packages are built THEN clean sources exclude build artifacts" (
      lib.hasInfix ''zellijNavSwitcherRoot = ../../dotfiles/zellij/nav/wasm/switcher'' zellijOverlay
      && lib.hasInfix ''src = cleanZellijSource zellijNavRoot ["target/" "wasm/"]'' zellijOverlay
      && lib.hasInfix ''src = cleanZellijSource zellijNavSwitcherRoot ["target/"]'' zellijOverlay
    ))
    (assert' "GIVEN zellij overlay WHEN wasm switcher links native dependencies THEN OpenSSL inputs are explicit" (
      lib.hasInfix ''nativeBuildInputs = [prev.pkg-config]'' zellijOverlay
      && lib.hasInfix ''OPENSSL_INCLUDE_DIR = "''${prev.openssl.dev}/include"'' zellijOverlay
      && lib.hasInfix ''OPENSSL_LIB_DIR = "''${prev.openssl.out}/lib"'' zellijOverlay
      && lib.hasInfix ''cargo build --offline --release --target wasm32-wasip1'' zellijOverlay
    ))
    (assert' "GIVEN zellij plugin source WHEN packaging switcher THEN plugin contract matches zellij 0.45" (
      !(builtins.pathExists ../../dotfiles/zellij/plugins)
      && lib.hasInfix ''zellij-tile = "0.45.1"'' navPluginCargo
      && lib.hasInfix ''switch_session_with_focus'' navPluginRust
      && lib.hasInfix ''cli_pipe_output'' navPluginRust
      && !(lib.hasInfix ''FullHdAccess'' zellijModule)
      && !(lib.hasInfix ''request_permission'' navPluginRust)
    ))
    (assert' "zellij-navigation: fish auto-routes only plain project launches" (
      lib.hasInfix ''programs.fish.functions.zellij'' zellijModule
      && lib.hasInfix ''if not status is-interactive'' zellijModule
      && lib.hasInfix ''if test (count $argv) -gt 0'' zellijModule
      && lib.hasInfix ''zellij-nav auto-project'' zellijModule
      && lib.hasInfix ''ZELLIJ_NAV_SIDECAR_COMMAND'' zellijModule
      && lib.hasInfix ''if test $auto_status -eq 2'' zellijModule
      && lib.hasInfix ''command ''${pkgs.zellij}/bin/zellij $argv'' zellijModule
    ))
    (assert' "zellij-navigation: docs are compact readme-owned principles" (
      !(builtins.pathExists ../../dotfiles/zellij/docs)
      && lib.hasInfix ''# Zellij Navigation'' zellijReadme
      && lib.hasInfix ''Bash는 entrypoint compatibility만 유지한다'' zellijReadme
      && lib.hasInfix ''Feature slice는 데이터 모델과 정책을 가까이 둔다'' zellijReadme
      && lib.hasInfix ''WASM derivation은 빌드 시간이 길 수'' zellijReadme
    ))
  ];
}
