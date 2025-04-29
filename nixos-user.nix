{ config, pkgs, ... }: {
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";
  home.stateVersion = "23.11"; # Don't change after first setup
}
