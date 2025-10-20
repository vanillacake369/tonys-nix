# Desktop environment: X Server, GNOME, display manager
{
  lib,
  pkgs,
  ...
}: {
  # Enabling hyprland on NixOS
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables = {
    # If your cursor becomes invisible
    WLR_NO_HARDWARE_CURSORS = "1";
    # Hint electron apps to use wayland
    NIXOS_OZONE_WL = "1";
  };

  # WayVNC for remote access
  environment.systemPackages = with pkgs; [
    wayvnc
  ];

  hardware = {
    # OpenGL
    graphics.enable = true;

    # Most wayland compositors need this
    nvidia.modesetting.enable = true;
  };

  # X Server configuration
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    config = lib.mkAfter ''
      Section "ServerFlags"
        Option "DontVTSwitch" "True"
      EndSection
    '';
  };

  # Display manager and desktop environment
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # SystemD journal configuration for SSD optimization
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemMaxFileSize=50M
    SystemMaxFiles=10
    MaxRetentionSec=1month
  '';

  # Logind configuration to prevent unwanted system actions
  services.logind = {
    settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandlePowerKey = "ignore";
        HandleSuspendKey = "ignore";
        HandleHibernateKey = "ignore";
        HandlePowerKeyLongPress = "ignore";
        IdleAction = "ignore";
        IdleActionSec = "0";
      };
    };
  };
}
