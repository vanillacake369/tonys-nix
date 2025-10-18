# Desktop environment: X Server, GNOME, display manager
{
  pkgs,
  lib,
  ...
}: {
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

  # Programs for desktop environment
  programs.firefox.enable = true;
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.java = {
    enable = true;
    package = pkgs.zulu17;
  };

  # Enable nix-ld for running dynamically linked executables
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # Basic system libraries
      stdenv.cc.cc
      zlib
      openssl
      curl

      # Python-related libraries (for claude-monitor and other Python tools)
      libffi
      glib

      # CLI tool dependencies
      ncurses
      readline
    ];
  };
}
