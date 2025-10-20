# NixOS 24.11 packages overlay
# Makes nixos-24.11 packages available alongside unstable packages
# Usage: pkgs.nixos-24_11.packageName
{nixos-24_11}: final: prev: {
  nixos-24_11 = import nixos-24_11 {
    inherit (final) system;
    config = final.config;
  };
}
