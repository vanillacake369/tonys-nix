{
  lib,
  pkgs,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: let
  # GUI packages that need Spotlight integration on macOS
  guiPackages = lib.optionals (!isWsl) [
    { pkg = pkgs.google-chrome; name = "Google Chrome"; }
    { pkg = pkgs.jetbrains.idea-ultimate; name = "IntelliJ IDEA"; }
    { pkg = pkgs.jetbrains.goland; name = "GoLand"; }
    { pkg = pkgs.jetbrains.datagrip; name = "DataGrip"; }
    { pkg = pkgs.drawio; name = "draw.io"; }
    { pkg = pkgs.discord; name = "Discord"; }
    { pkg = pkgs.obsidian; name = "Obsidian"; }
    { pkg = pkgs.wezterm; name = "WezTerm"; }
  ] ++ lib.optionals isDarwin [
    { pkg = pkgs.hidden-bar; name = "Hidden Bar"; }
    { pkg = pkgs.aldente; name = "AlDente"; }
    { pkg = pkgs.bartender; name = "Bartender 4"; }
    { pkg = pkgs.keycastr; name = "KeyCastr"; }
  ];

  # Simple function to create app symlinks for Spotlight
  mkAppLink = app: {
    "Applications/${app.name}.app".source = "${app.pkg}/Applications/${app.name}.app";
  };
in {
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
      hidden-bar
      aldente
      bartender
      yabai
      skhd
      # karabiner-elements
      keycastr
      # Slack has known issues on macOS Sequoia, may need Homebrew fallback
      # slack
    ];

  # Create app symlinks for macOS Spotlight integration
  home.file = lib.mkIf isDarwin (lib.mkMerge (map mkAppLink guiPackages));
}
