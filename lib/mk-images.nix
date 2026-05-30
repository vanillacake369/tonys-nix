# Generates QCOW2/ISO/VMware/VirtualBox images for Linux systems.
# Uses nixpkgs-native `system.build.images` (upstreamed into nixpkgs as of
# NixOS 25.05) — replaces the deprecated nixos-generators flake.
# Each variant is layered onto the base config via the module system's
# `extendModules`, so the format modules never conflict with one another.
{
  lib,
  nixpkgs,
  configModules,
}: system:
lib.optionalAttrs (lib.hasSuffix "-linux" system) (
  let
    images =
      (nixpkgs.lib.nixosSystem {
        inherit system;
        modules = configModules;
      })
        .config.system.build.images;
  in
    {
      iso = images.iso;
      qcow = images.qemu;
      vmware = images.vmware;
    }
    // lib.optionalAttrs (system == "x86_64-linux") {
      virtualbox = images.virtualbox;
    }
)
