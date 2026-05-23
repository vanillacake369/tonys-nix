# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
{lib, ...}: {
  imports =
    # Include the results of the hardware scan.
    # NOTE: hardware-configuration.nix is stored in /etc/nixos/ (outside flake)
    # Generate it on each new machine with: sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
    # Only import if the file exists (for actual NixOS systems)
    lib.optionals (builtins.pathExists /etc/nixos/hardware-configuration.nix) [
      /etc/nixos/hardware-configuration.nix
    ]
    # Fallback for non-NixOS environments (macOS, CI) where hardware-configuration.nix is absent.
    # mkDefault ensures real hardware-configuration.nix takes precedence on actual NixOS machines.
    ++ lib.optionals (! builtins.pathExists /etc/nixos/hardware-configuration.nix) [
      {
        fileSystems."/" = lib.mkDefault {
          device = "/dev/sda1";
          fsType = "ext4";
        };
        boot.loader.grub.device = lib.mkDefault "/dev/sda";
      }
    ]
    ++ [
      # System configuration modules
      ./nixos-modules/boot.nix
      ./nixos-modules/locale.nix
      ./nixos-modules/desktop.nix
      ./nixos-modules/remote-desktop.nix
      ./nixos-modules/hardware.nix
      ./nixos-modules/security.nix
      ./nixos-modules/network.nix
      ./nixos-modules/nix-settings.nix
      ./nixos-modules/virtualization.nix
      ./nixos-modules/power.nix
      ./nixos-modules/users.nix
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
