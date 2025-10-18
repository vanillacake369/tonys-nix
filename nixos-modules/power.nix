# Power management and sleep configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Disable systemd sleep targets to prevent automatic suspend/hibernate
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Power management - disable automatic suspend/hibernate
  powerManagement = {
    enable = false;
    powertop.enable = false;
  };
}
