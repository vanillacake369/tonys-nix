# NixOS-specific settings and configurations (Hyprland)
{
  lib,
  pkgs,
  ...
}: {
  # =============================================================================
  # Hyprland Wayland Compositor Settings
  # =============================================================================

  # Wayland-specific environment variables
  home.sessionVariables = {
    # Wayland native support for various applications
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # =============================================================================
  # Systemd Initiation
  # =============================================================================
  # Auto-start systemd user services
  systemd.user.startServices = "sd-switch";
}
