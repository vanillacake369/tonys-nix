# Container and virtualization configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable common container config files in /etc/containers
  virtualisation = {
    containers = {
      enable = true;
      registries = {
        search = ["docker.io"]; # could be replaced with 'quay.io'
        insecure = [];
        block = [];
      };
    };
    # VirtualBox disabled due to build failures with VirtualBox 7.2.0 and libcurl compatibility
    # Using Podman as container runtime instead
    # virtualbox.host.enable = true;
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
