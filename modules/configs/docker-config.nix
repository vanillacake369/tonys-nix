{ config, pkgs, lib, username, ... }: {

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable rootless Docker (optional)
  virtualisation.docker.rootless = false;

  # Add user to Docker group
  users.users.${username}.extraGroups = [ "docker" ];

}

