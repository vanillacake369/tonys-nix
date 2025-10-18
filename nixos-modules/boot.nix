# Boot loader and kernel configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelParams = ["kvm.enable_virt_at_load=0"];
    blacklistedKernelModules = [
      "kvm"
      "kvm_intel"
      "kvm_amd"
    ];
  };
}
