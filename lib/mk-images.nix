# Generates QCOW2/ISO/VMware/VirtualBox images for Linux systems.
{
  lib,
  nixos-generators,
  configModules,
}: system:
lib.optionalAttrs (lib.hasSuffix "-linux" system) (
  lib.mapAttrs
  (_: fmt:
    nixos-generators.nixosGenerate {
      inherit system;
      modules = configModules;
      format = fmt;
    })
  ({
      iso = "iso";
      vmware = "vmware";
      qcow = "qcow";
    }
    // lib.optionalAttrs (system == "x86_64-linux") {
      virtualbox = "virtualbox";
    })
)
