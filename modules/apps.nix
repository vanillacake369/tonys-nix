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
      openvpn
    ]
    ++ lib.optionals (!isWsl) [
      # Non WSL apps
      google-chrome
      jetbrains.idea-ultimate
      jetbrains.goland
      jetbrains.datagrip
      drawio
      discord
      obsidian
      wezterm
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
      aldente
      bartender
      yabai
      skhd
      keycastr
      raycast
      jankyborders
    ];
}
