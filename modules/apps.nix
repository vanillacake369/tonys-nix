{
  lib,
  pkgs,
  isWsl,
  isDarwin,
  isLinux,
  isNixOs ? false,
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
    ++ lib.optionals isNixOs [
      # NixOS-specific apps
      ulauncher
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
    ];
}
