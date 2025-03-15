{ config, pkgs, lib, ... }: {

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable rootless Docker (optional)
  virtualisation.docker.rootless = false;

}

