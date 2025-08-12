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
    ];

  # Create app symlinks for macOS Spotlight integration
  home.file = lib.mkIf isDarwin {
    "Applications/Google Chrome.app".source = "${pkgs.google-chrome}/Applications/Google Chrome.app";
    "Applications/IntelliJ IDEA.app".source = "${pkgs.jetbrains.idea-ultimate}/Applications/IntelliJ IDEA.app";
    "Applications/GoLand.app".source = "${pkgs.jetbrains.goland}/Applications/GoLand.app";
    "Applications/DataGrip.app".source = "${pkgs.jetbrains.datagrip}/Applications/DataGrip.app";
    "Applications/draw.io.app".source = "${pkgs.drawio}/Applications/draw.io.app";
    "Applications/Discord.app".source = "${pkgs.discord}/Applications/Discord.app";
    "Applications/Obsidian.app".source = "${pkgs.obsidian}/Applications/Obsidian.app";
    "Applications/WezTerm.app".source = "${pkgs.wezterm}/Applications/WezTerm.app";
    "Applications/Hidden Bar.app".source = "${pkgs.hidden-bar}/Applications/Hidden Bar.app";
    "Applications/AlDente.app".source = "${pkgs.aldente}/Applications/AlDente.app";
    "Applications/Bartender 4.app".source = "${pkgs.bartender}/Applications/Bartender 4.app";
    "Applications/KeyCastr.app".source = "${pkgs.keycastr}/Applications/KeyCastr.app";
  };
}
