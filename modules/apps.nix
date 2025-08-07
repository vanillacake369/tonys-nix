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
    ]
    ++ lib.optionals (!isWsl) [
      google-chrome
      jetbrains.idea-ultimate
      jetbrains.goland
      jetbrains.datagrip
      slack
      firefox
      libreoffice
      hunspell
      hunspellDicts.en_US
      hunspellDicts.ko_KR
      hunspellDicts.ko-kr
      drawio
      openvpn
      openvpn3
      discord
      ytmdesktop
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Linux-specific apps  
      ticktick
    ]
    ++ lib.optionals isDarwin [
      # MacOs Apps
      hidden-bar
      aldente
      bartender
      yabai
      skhd
    ];
}
