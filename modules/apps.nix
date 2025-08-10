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

  # macOS-specific: Create Spotlight trampolines for GUI apps
  home.activation.makeTrampolineApps = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      echo "Setting up macOS app trampolines for Spotlight..."
      
      fromDir="$HOME/Applications/Home Manager Apps"
      toDir="$HOME/Applications/Home Manager Trampolines"
      
      # Ensure target directory exists
      mkdir -p "$toDir"
      
      # Create trampolines for all apps in source directory
      if [ -d "$fromDir" ]; then
        echo "[Trampolines] Scanning for apps in: $fromDir"
        (
          cd "$fromDir"
          for app in *.app; do
            if [ -d "$app" ]; then
              echo "[Trampolines] Creating trampoline for: $app"
              
              # Create AppleScript app that opens the real app
              /usr/bin/osacompile -o "$toDir/$app" -e "do shell script \"open '$fromDir/$app'\""
              
              # Copy icon if it exists
              iconPath=$(find "$fromDir/$app/Contents/Resources" -name "*.icns" -type f | head -n 1)
              if [ -n "$iconPath" ] && [ -f "$iconPath" ]; then
                cp "$iconPath" "$toDir/$app/Contents/Resources/applet.icns"
                # Touch the app to refresh Finder's icon cache
                touch "$toDir/$app"
              fi
            fi
          done
        )
      else
        echo "[Trampolines] Source directory not found: $fromDir"
      fi
      
      # Clean up orphaned trampolines
      if [ -d "$toDir" ]; then
        echo "[Trampolines] Cleaning up orphaned trampolines..."
        (
          cd "$toDir"
          for app in *.app; do
            if [ ! -d "$fromDir/$app" ]; then
              echo "[Trampolines] Removing orphaned trampoline: $app"
              rm -rf "$toDir/$app"
            fi
          done
        )
      fi
      
      echo "[Trampolines] Setup complete!"
    ''
  );
}
