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
      # General apps
      claude-code
    ]
    ++ lib.optionals (!isWsl) [
      # Non WSL apps
      google-chrome
      obsidian
      jetbrains.idea-ultimate
      jetbrains.goland
      jetbrains.datagrip
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Linux-specific apps
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
      # MacOs Apps
      aldente
      yabai
      skhd
      raycast
      jankyborders
      appcleaner
      hidden-bar
      discord
      wezterm
    ];
}
