{
  lib,
  pkgs,
  isLinux,
  isDarwin,
  isWsl,
  ...
}: let
  # Define Windows user path variables once for cleaner code
  winUserDir = "/mnt/c/Users/limjihoon";
  taskXmlName = "SystemIdleShutdown.xml";
  taskName = "SystemIdleShutdown";
  winXmlPath = "C:\\Users\\limjihoon\\${taskXmlName}";
  wslXmlPath = "${winUserDir}/${taskXmlName}";

  # Check if running with Windows administrator privileges (WSL only)
  # This is a build-time check that runs during home-manager activation
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
  # Enable Home Manager
  programs.home-manager.enable = true;

  # Set env automatically (Linux only)
  targets.genericLinux.enable = isLinux;

  # Copy Windows files for WSL
  # - AutoHotkey
  # - Shutdown scheduler via Win32 Task Scheduler
  home.activation = lib.mkIf isWsl {
    copyAutoHotkeyScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run cp -f ${./dotfiles/autohotkey/win11-shortcut.ahk} \
        "/mnt/c/Users/limjihoon/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/win11-shortcut.ahk"
    '';

    # Copy Windows shutdown script (only if running as administrator)
    copyWindowsShutdownScript = lib.hm.dag.entryAfter ["writeBoundary"] (
      if isWindowsAdmin
      then ''
        echo "✓ Windows administrator access detected, copying shutdown script..."
        run cp -f ${./dotfiles/windows/script/shutdown_idle.ps1} \
          "/mnt/c/Users/limjihoon/shutdown_idle.ps1"
      ''
      else ''
        echo "☝ No Windows administrator access. Skipping shutdown script installation."
        echo "To enable this feature, run WSL as administrator."
      ''
    );

    # Register Windows Scheduled Task (only if running as administrator)
    # 1. Copy XML file to a temporary, accessible location on the Windows drive.
    # 2. Execute the native Windows 'schtasks.exe' binary to properly register the task.
    # 3. Clean up the temporary XML file.
    registerWindowsSchedulerTask = lib.hm.dag.entryAfter ["writeBoundary"] (
      if isWindowsAdmin
      then ''
        echo "Windows administrator access confirmed, registering task..."

        # 1. Copy XML to Windows user directory (must be a .xml file for registration)
        run cp -f ${./dotfiles/windows/scheduler/SystemIdleShutdown.xml} \
          "${wslXmlPath}"

        # 2. Register the task using schtasks.exe (must use Windows path format for the XML)
        # /create: create a new task
        # /tn: task name
        # /xml: path to the XML definition file in the Windows format
        # /F: force overwrite if the task already exists
        run /mnt/c/Windows/System32/schtasks.exe /create /tn "${taskName}" /xml "${winXmlPath}" /F

        # 3. Clean up the temporary XML file
        run rm -f "${wslXmlPath}"
      ''
      else ''
        echo "☝ No Windows administrator access. Skipping task registration."
        echo "To enable this feature, run WSL as administrator:"
        echo "  1. Close this WSL session"
        echo "  2. Open Windows Terminal or Command Prompt as Administrator"
        echo "  3. Run: wsl"
        echo "  4. Then run: just install-pckgs"
      ''
    );
  };

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
    }
    // lib.optionalAttrs isDarwin {
      # Karabiner json
      ".config/karabiner/karabiner.json".source = ./dotfiles/karabiner/karabiner.json;

      # Yabai & Skhd (Mac only)
      ".config/yabai/yabairc".source = ./dotfiles/yabai/yabairc;
      ".skhdrc".source = ./dotfiles/skhd/skhdrc;
    };

  # Packages
  imports = [
    ./modules/infra.nix
    ./modules/language.nix
    ./modules/nvim.nix
    ./modules/zsh.nix
    ./modules/shell.nix
    ./modules/apps.nix
    ./dotfiles/jetbrain/jetbrains.nix
  ];
}
