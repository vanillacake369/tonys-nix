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
      openvpn
    ]
    ++ lib.optionals (!isWsl) [
      google-chrome
      jetbrains.idea-ultimate
      jetbrains.goland
      jetbrains.datagrip
      drawio
      discord
      obsidian
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
      openvpn3
    ]
    ++ lib.optionals isDarwin [
      # MacOs Apps
      hidden-bar
      aldente
      bartender
      yabai
      skhd
      karabiner-elements
      keycastr
      # Slack has known issues on macOS Sequoia, may need Homebrew fallback
      # slack
    ];
}
