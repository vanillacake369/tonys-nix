{ pkgs, isWsl, ... }:
{

  home.packages =
    with pkgs;
    [
      claude-code
    ]
    ++ lib.optionals (!isWsl) [
      google-chrome
      jetbrains.idea-ultimate
      jetbrains.goland
      jetbrains.datagrip
      youtube-music
      ticktick
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
      warp-terminal
      code-cursor
    ];
}
