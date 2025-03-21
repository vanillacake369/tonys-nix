{
  pkgs ? import <nixpkgs> { system = "x86_64-linux"; }
}:
pkgs.dockerTools.buildLayeredImage {
  name = "nix-redis";
  tag = "latest";
  contents = [ pkgs.redis ];
}
