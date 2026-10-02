# WSL-specific settings (JetBrains keymap linking moved to packages/jetbrains.nix)
{
  lib,
  userProfile,
  ...
}: let
  winUserDir = userProfile.windowsHome;

  # Windows admin status is a runtime/activation concern, not a build-time fact:
  # the build host may differ from the activation host, and admin rights can
  # change between `nix build` and `home-manager switch`. Checked live below.
  adminCheck = "/mnt/c/Windows/System32/net.exe session";
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

    copyWindowsShutdownScript = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ${adminCheck} >/dev/null 2>&1; then
        run cp -f ${../../dotfiles/windows/script/shutdown_idle.ps1} \
          "${winUserDir}/shutdown_idle.ps1"
      else
        echo "No Windows admin access. Skipping shutdown script."
      fi
    '';
  };
}
