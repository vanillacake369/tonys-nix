{
  lib,
  pkgs,
  config,
  isLinux,
  isDarwin,
  isWsl,
  ...
}: {
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Set env automatically (Linux only)
  targets.genericLinux.enable = isLinux;

  # Import dotfiles
  home.file =
    {
      ".config/nix".source = ./dotfiles/nix;
      ".config/nixpkgs".source = ./dotfiles/nixpkgs;
      ".config/nvim".source = ./dotfiles/lazyvim;
      ".screenrc".source = ./dotfiles/screen/.screenrc;

      # Claude configuration - only manage static files
      ".claude/commands".source = ./dotfiles/claude/commands;
      ".claude/settings.json".source = ./dotfiles/claude/settings.json;
      ".claude/CLAUDE.md".source = ./dotfiles/claude/CLAUDE.md;
      ".claude/agents".source = ./dotfiles/claude/agents;

      # Zellij configuration
      ".config/zellij/config.kdl".source =
        if isDarwin
        then ./dotfiles/zellij/config.kdl.darwin
        else ./dotfiles/zellij/config.kdl.linux;

      # Karabiner json
      ".config/karabiner/karabiner.json".source = ./dotfiles/karabiner/karabiner.json;
    }
    // lib.optionalAttrs isDarwin {
      # macOS-specific configurations
      ".config/yabai/yabairc".source = ./dotfiles/yabai/yabairc;
      ".skhdrc".source = ./dotfiles/skhd/skhdrc;
    };

  # Packages
  imports =
    [
      ./modules/infra.nix
      ./modules/language.nix
      ./modules/nvim.nix
      ./modules/zsh.nix
      ./modules/shell.nix
      ./modules/apps.nix
    ];

  # Activation scripts
  home.activation = lib.mkIf isDarwin {
    linkJetBrainsKeymaps = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Source keymap file in the repository
      SOURCE_KEYMAP="${config.home.homeDirectory}/dev/tonys-nix/dotfiles/jetbrain/keymap/Windows.xml"
      
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
  };
}
