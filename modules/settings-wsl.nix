# WSL-specific settings and configurations
{
  config,
  lib,
  pkgs,
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
    > 0;
in {
  # =============================================================================
  # WSL X Server Display Configuration
  # =============================================================================
  home.sessionVariables = {
    DISPLAY = ":0.0";
    LIBGL_ALWAYS_INDIRECT = "1";
  };

  # =============================================================================
  # Systemd Initiation
  # =============================================================================
  # Auto-start systemd user services
  systemd.user.startServices = "sd-switch";

  # =============================================================================
  # Home Activation Scripts - WSL Windows Integration
  # =============================================================================
  home.activation = {
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

    # WSL JetBrains keymap linking
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
  };
}
