{
  lib,
  pkgs,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  home.packages = with pkgs;
    [
      claude-code
      gemini-cli
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
    ];
}
