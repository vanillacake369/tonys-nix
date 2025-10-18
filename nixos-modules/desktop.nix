# Desktop environment: X Server, GNOME, display manager
{lib, ...}: {
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
