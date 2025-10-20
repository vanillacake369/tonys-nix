# macOS-specific settings and configurations
{
  config,
  lib,
  ...
}: {
  # =============================================================================
  # Home Activation Scripts - macOS JetBrains Integration
  # =============================================================================
  home.activation = {
    # macOS JetBrains keymap linking
    linkJetBrainsKeymaps = lib.hm.dag.entryAfter ["writeBoundary"] ''
      SOURCE_KEYMAP="${config.home.homeDirectory}/dev/tonys-nix/dotfiles/jetbrain/keymap/Mac.xml"
      JETBRAINS_DIR="${config.home.homeDirectory}/Library/Application Support/JetBrains"

      if [[ -d "$JETBRAINS_DIR" && -f "$SOURCE_KEYMAP" ]]; then
        echo "Setting up JetBrains keymaps for macOS..."
        for ide_dir in "$JETBRAINS_DIR"/{IntelliJIdea,GoLand,DataGrip,WebStorm,PhpStorm,PyCharm,RubyMine,CLion,Rider,AndroidStudio}*; do
          if [[ -d "$ide_dir" ]]; then
            KEYMAP_DIR="$ide_dir/keymaps"
            mkdir -p "$KEYMAP_DIR"
            rm -f "$KEYMAP_DIR/Mac.xml"
            ln -sf "$SOURCE_KEYMAP" "$KEYMAP_DIR/Mac.xml"
            echo "✓ Linked keymap for $(basename "$ide_dir")"
          fi
        done
      fi
    '';
  };
}
