# System-wide settings and configurations
# Organized by platform: WSL, GNOME, macOS
{
  config,
  lib,
  pkgs,
  isWsl,
  isNixOs,
  isDarwin,
  isLinux,
  ...
}: let
  # =============================================================================
  # WSL Configuration Variables
  # =============================================================================
  winUserDir = "/mnt/c/Users/limjihoon";
  taskXmlName = "SystemIdleShutdown.xml";
  taskName = "SystemIdleShutdown";
  winXmlPath = "C:\\Users\\limjihoon\\${taskXmlName}";
  wslXmlPath = "${winUserDir}/${taskXmlName}";

  # Check Windows admin privileges
  isWindowsAdmin =
    if isWsl
    then
      (builtins.compareVersions
        (builtins.readFile (
          pkgs.runCommand "check-windows-admin" {} ''
            if /mnt/c/Windows/System32/net.exe session >/dev/null 2>&1; then
              echo -n "1" > $out
            else
              echo -n "0" > $out
            fi
          ''
        ))
        "0")
      > 0
    else false;
in {
  # =============================================================================
  # GNOME Desktop Settings (dconf)
  # =============================================================================
  dconf.settings = lib.mkIf isNixOs {
    # Touchpad configuration for GNOME/Wayland
    "org/gnome/desktop/peripherals/touchpad" = {
      speed = 0.3;
      scroll-factor = 3.0;
      tap-to-click = true;
      tap-and-drag = true;
      tap-and-drag-lock = false;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
      edge-scrolling-enabled = false;
      disable-while-typing = true;
      click-method = "fingers";
      tap-button-map = "default";
      middle-click-emulation = false;
      accel-profile = "custom";
    };

    # Mouse configuration
    "org/gnome/desktop/peripherals/mouse" = {
      speed = 0.3;
      accel-profile = "flat";
      natural-scroll = true;
    };

    # Media key bindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      volume-up = ["<Ctrl><Alt>Up"];
      volume-down = ["<Ctrl><Alt>Down"];
      next = ["<Shift><Control>n"];
      previous = ["<Shift><Control>p"];
      play = ["<Shift><Control>space"];
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
      ];
    };

    # Custom application launcher keybindings
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "gnome console";
      command = "kgx";
      binding = "<Ctrl><Alt>t";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "intellij";
      command = "idea-ultimate";
      binding = "<Ctrl><Alt>i";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "goland";
      command = "goland";
      binding = "<Ctrl><Alt>g";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
      name = "google chrome";
      command = "google-chrome-stable";
      binding = "<Ctrl><Alt>c";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      name = "youtube music desktop";
      command = "ytmdesktop";
      binding = "<Ctrl><Alt>m";
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      name = "Capture";
      command = "gnome-screenshot -i";
      binding = "<Super><Shift>s";
    };

    # Disable workspace switching with Ctrl+Alt+Up/Down
    "org/gnome/desktop/wm/keybindings" = {
      switch-to-workspace-up = [];
      switch-to-workspace-down = [];
      switch-to-workspace-left = [];
      switch-to-workspace-right = [];
    };

    # Power management and idle settings
    "org/gnome/desktop/session" = {
      idle-delay = 900;
    };

    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
      lock-delay = 0;
    };

    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-ac-timeout = 0;
      sleep-inactive-battery-type = "nothing";
      sleep-inactive-battery-timeout = 0;
      sleep-inactive-ac-blank-timeout = 0;
      sleep-inactive-battery-blank-timeout = 0;
      idle-dim = false;
      ambient-enabled = false;
      power-button-action = "interactive";
    };
  };

  # =============================================================================
  # Systemd Initiation
  # =============================================================================
  # Auto-start systemd user services
  systemd.user.startServices = lib.mkIf isLinux "sd-switch";

  # =============================================================================
  # Home Activation Scripts
  # =============================================================================
  home.activation = lib.mkMerge [
    # WSL Windows Integration
    (lib.mkIf isWsl {
      # Copy AutoHotkey startup script
      copyAutoHotkeyScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run cp -f ${../dotfiles/autohotkey/win11-shortcut.ahk} \
          "/mnt/c/Users/limjihoon/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/win11-shortcut.ahk"
      '';

      # Copy Windows shutdown script (requires admin)
      copyWindowsShutdownScript = lib.hm.dag.entryAfter ["writeBoundary"] (
        if isWindowsAdmin
        then ''
          echo "✓ Windows admin detected, copying shutdown script..."
          run cp -f ${../dotfiles/windows/script/shutdown_idle.ps1} \
            "${winUserDir}/shutdown_idle.ps1"
        ''
        else ''
          echo "☝️No Windows admin access. Skipping shutdown script."
        ''
      );

      # Register Windows scheduled task (requires admin)
      registerWindowsSchedulerTask = lib.hm.dag.entryAfter ["writeBoundary"] (
        if isWindowsAdmin
        then ''
          echo "✓ Registering Windows scheduled task..."
          run cp -f ${../dotfiles/windows/scheduler/SystemIdleShutdown.xml} "${wslXmlPath}"
          run /mnt/c/Windows/System32/schtasks.exe /create /tn "${taskName}" /xml "${winXmlPath}" /F
          run rm -f "${wslXmlPath}"
        ''
        else ''
          echo "☝️No Windows admin access. Skipping scheduled task registration."
        ''
      );
    })

    # macOS JetBrains keymap linking
    (lib.mkIf isDarwin {
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
    })

    # WSL keymap linking
    (lib.mkIf isWsl {
      linkJetBrainsKeymapsWSL = lib.hm.dag.entryAfter ["writeBoundary"] ''
        SOURCE_KEYMAP="${config.home.homeDirectory}/dev/tonys-nix/dotfiles/jetbrain/keymap/Windows.xml"
        JETBRAINS_DIR="/mnt/c/Users/limjihoon/AppData/Roaming/JetBrains"

        if [[ -d "$JETBRAINS_DIR" && -f "$SOURCE_KEYMAP" ]]; then
          echo "Setting up JetBrains keymaps for WSL..."
          for ide_dir in "$JETBRAINS_DIR"/{IntelliJIdea,GoLand,DataGrip,WebStorm,PhpStorm,PyCharm,RubyMine,CLion,Rider,AndroidStudio}*; do
            if [[ -d "$ide_dir" ]]; then
              KEYMAP_DIR="$ide_dir/keymaps"
              mkdir -p "$KEYMAP_DIR"
              rm -f "$KEYMAP_DIR/Windows.xml"
              ln -sf "$SOURCE_KEYMAP" "$KEYMAP_DIR/Windows.xml"
              echo "✓ Linked keymap for $(basename "$ide_dir")"
            fi
          done
        fi
      '';
    })
  ];
}
