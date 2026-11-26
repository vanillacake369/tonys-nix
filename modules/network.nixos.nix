# Network configuration, firewall, and shared services
{lib, ...}: {
  # Firewall of inbound traffic
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall = {
      enable = lib.mkDefault true; # Allow override for image formats that disable firewall
      # Add firewall exception for libvirt provider when using NFSv4
      interfaces."virbr1" = {
        allowedTCPPorts = [2049];
        allowedUDPPorts = [2049];
      };
      # Allow ports
      allowedTCPPorts = [
        # SSH
        22
      ];
    };
  };

  # NFS services
  services = {
    nfs.server.enable = true;
  };
}
