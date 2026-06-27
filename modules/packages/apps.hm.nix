{
  lib,
  pkgs,
  isWsl,
  isDarwin,
  isLinux,
  userProfile,
  ...
}: let
  keymaps = import ../keymap/pipeline.nix {inherit lib userProfile;};
in {
  home.packages = with pkgs;
    [
      claude-code
      antigravity-cli
      codex
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      firefox
      slack
      ticktick
      ytmdesktop
      libreoffice
      hunspell
      hunspellDicts.en_US
      hunspellDicts.ko_KR
      hunspellDicts.ko-kr
    ]
    ++ lib.optionals isDarwin [
      aldente
      jankyborders
      appcleaner
      wezterm
      aerospace
      hidden-bar
      telegram-desktop
    ];

  home.file =
    {
      ".wezterm.lua".source = ../../dotfiles/wezterm/wezterm.lua;
    }
    // lib.optionalAttrs isDarwin {
      ".config/karabiner/karabiner.json" = {
        text = keymaps.karabinerJson;
        force = true;
      };
      ".config/aerospace/aerospace.toml" = {
        text = keymaps.aerospaceToml;
        force = true;
      };
    };
}
