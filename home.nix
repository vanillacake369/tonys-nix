{
  lib,
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

    copyWindowsShutdownScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run cp -f ${./dotfiles/windows/script/shutdown_idle.ps1} \
        "/mnt/c/Users/limjihoon/shutdown_idle.ps1"
    '';

    # CORRECT WAY TO REGISTER A WINDOWS SCHEDULED TASK
    # 1. Copy XML file to a temporary, accessible location on the Windows drive.
    # 2. Execute the native Windows 'schtasks.exe' binary to properly register the task.
    # 3. Clean up the temporary XML file.
    registerWindowsSchedulerTask = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
    '';
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
