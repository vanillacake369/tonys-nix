# Remote desktop configuration: VNC server (wayvnc)
{pkgs, ...}: {
  # WayVNC package for remote access
  environment.systemPackages = with pkgs; [
    wayvnc
  ];

  # Firewall configuration for VNC access
  networking.firewall = {
    allowedTCPPorts = [
      5900 # VNC (wayvnc)
    ];
  };
}
