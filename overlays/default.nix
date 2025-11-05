# Default overlay aggregator
# Imports and combines all overlays from this directory
{}: [
  # Chrome overlay with Wayland optimizations
  (import ./chrome.nix)

  # Slack overlay with Wayland optimizations
  (import ./slack.nix)
]
