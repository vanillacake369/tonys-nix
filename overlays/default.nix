# Default overlay aggregator
# Imports and combines all overlays from this directory
{nixos-24_11}: [
  # Multipass overlay for WSL (removes GUI dependencies)
  (import ./multipass.nix)

  # Chrome overlay with Wayland optimizations
  (import ./chrome.nix)

  # Slack overlay with Wayland optimizations
  (import ./slack.nix)

  # NixOS 24.11 packages availability
  (import ./nixos-24-11.nix {inherit nixos-24_11;})
]
