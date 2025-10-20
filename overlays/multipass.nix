# Overlay to use stable NixOS 24.11 multipass instead of unstable
# Testing if the stable version (1.14.1) works better than unstable (1.16.1)
{nixos-24_11}: final: prev: let
  # Import nixos-24.11 packages for this system
  stable = import nixos-24_11 {
    inherit (final) system;
    config = final.config;
  };
in {
  # Use stable multipass directly - it doesn't have GUI issues in 24.11
  multipass = stable.multipass.override {
    # Override to ensure it works in WSL environment
  };
}
