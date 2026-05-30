# WSL-specific settings (JetBrains keymap linking moved to packages/jetbrains.nix)
{
  lib,
  pkgs,
  userProfile,
  ...
}: let
  winUserDir = userProfile.windowsHome;
  taskXmlName = "SystemIdleShutdown.xml";
  taskName = "SystemIdleShutdown";
  winXmlPath = "C:\\Users\\${userProfile.username}\\${taskXmlName}";
  wslXmlPath = "${winUserDir}/${taskXmlName}";

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
  home.sessionVariables = {
    DISPLAY = ":0.0";
    LIBGL_ALWAYS_INDIRECT = "1";
  };

  systemd.user.startServices = "sd-switch";

  home.activation = {
    copyAutoHotkeyScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run cp -f ${../../dotfiles/autohotkey/win11-shortcut.ahk} \
        "${winUserDir}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/win11-shortcut.ahk"
    '';

    copyWindowsShutdownScript = lib.hm.dag.entryAfter ["writeBoundary"] (
      if isWindowsAdmin
      then ''
        run cp -f ${../../dotfiles/windows/script/shutdown_idle.ps1} \
          "${winUserDir}/shutdown_idle.ps1"
      ''
      else ''
        echo "No Windows admin access. Skipping shutdown script."
      ''
    );

    registerWindowsSchedulerTask = lib.hm.dag.entryAfter ["writeBoundary"] (
      if isWindowsAdmin
      then ''
        run cp -f ${../../dotfiles/windows/scheduler/SystemIdleShutdown.xml} "${wslXmlPath}"
        run /mnt/c/Windows/System32/schtasks.exe /create /tn "${taskName}" /xml "${winXmlPath}" /F
        run rm -f "${wslXmlPath}"
      ''
      else ''
        echo "No Windows admin access. Skipping scheduled task registration."
      ''
    );
  };
}
