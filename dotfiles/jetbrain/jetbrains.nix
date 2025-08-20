{
  lib,
  config,
  isDarwin,
  isWsl,
  ...
}: {
  # JetBrains IDE configuration and keymap management

  home.activation = lib.mkMerge [
    # macOS keymap configuration
    (lib.mkIf isDarwin {
      linkJetBrainsKeymaps = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Source keymap file in the repository
        SOURCE_KEYMAP="${config.home.homeDirectory}/dev/tonys-nix/dotfiles/jetbrain/keymap/Mac.xml"

        # JetBrains base directory
        JETBRAINS_DIR="${config.home.homeDirectory}/Library/Application Support/JetBrains"

        if [[ -d "$JETBRAINS_DIR" && -f "$SOURCE_KEYMAP" ]]; then
          echo "Setting up JetBrains keymaps..."

          # Find all JetBrains IDE directories
          for ide_dir in "$JETBRAINS_DIR"/{IntelliJIdea,GoLand,DataGrip,WebStorm,PhpStorm,PyCharm,RubyMine,CLion,Rider,AndroidStudio}*; do
            if [[ -d "$ide_dir" ]]; then
              KEYMAP_DIR="$ide_dir/keymaps"

              # Create keymaps directory if it doesn't exist
              mkdir -p "$KEYMAP_DIR"

              # Remove existing symlink or file if it exists
              if [[ -e "$KEYMAP_DIR/Mac.xml" ]]; then
                rm -f "$KEYMAP_DIR/Mac.xml"
              fi

              # Create symlink
              ln -sf "$SOURCE_KEYMAP" "$KEYMAP_DIR/Mac.xml"
              echo "✓ Linked keymap for $(basename "$ide_dir")"
            fi
          done
        fi
      '';
    })

    # WSL keymap configuration
    (lib.mkIf isWsl {
      linkJetBrainsKeymapsWSL = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Source keymap file in the repository
        SOURCE_KEYMAP="${config.home.homeDirectory}/dev/tonys-nix/dotfiles/jetbrain/keymap/Windows.xml"

        # JetBrains base directory on Windows
        JETBRAINS_DIR="/mnt/c/Users/limjihoon/AppData/Roaming/JetBrains"

        if [[ -d "$JETBRAINS_DIR" && -f "$SOURCE_KEYMAP" ]]; then
          echo "Setting up JetBrains keymaps for WSL..."

          # Find all JetBrains IDE directories
          for ide_dir in "$JETBRAINS_DIR"/{IntelliJIdea,GoLand,DataGrip,WebStorm,PhpStorm,PyCharm,RubyMine,CLion,Rider,AndroidStudio}*; do
            if [[ -d "$ide_dir" ]]; then
              KEYMAP_DIR="$ide_dir/keymaps"

              # Create keymaps directory if it doesn't exist
              mkdir -p "$KEYMAP_DIR"

              # Remove existing symlink or file if it exists
              if [[ -e "$KEYMAP_DIR/Windows.xml" ]]; then
                rm -f "$KEYMAP_DIR/Windows.xml"
              fi

              # Create symlink
              ln -sf "$SOURCE_KEYMAP" "$KEYMAP_DIR/Windows.xml"
              echo "✓ Linked keymap for $(basename "$ide_dir")"
            fi
          done
        fi
      '';
    })
  ];
}
