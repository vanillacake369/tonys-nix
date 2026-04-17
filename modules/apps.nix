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
      # claude-code
      gemini-cli
      codex
      # opencode
      tailscale
    ]
    ++ lib.optionals (!isWsl) [
      # Non WSL apps
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
      jetbrains.idea
      jetbrains.goland
      jetbrains.datagrip
    ]
    ++ lib.optionals isDarwin [
      # MacOs Apps
      aldente
      jankyborders
      appcleaner
      wezterm
      aerospace
      # shottr
    ];
}
