{
  lib,
  config,
  pkgs,
  isWsl ? false,
  ...
}: {
  home.username = "limjihoon";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/limjihoon" else "/home/limjihoon";
  home.stateVersion = "23.11"; # Don't change after first setup

  # GNOME dconf settings moved to nixos-modules/gnome-settings.nix
  # Import that module in home.nix or configuration.nix for GNOME desktop systems
}
