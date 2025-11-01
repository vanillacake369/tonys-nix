# General CLI utilities and tools
# Core utilities, terminal tools, recording, database clients
{
  config,
  pkgs,
  lib,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  # =============================================================================
  # General CLI Utilities
  # =============================================================================
  home.packages = with pkgs; [
    # Core utilities
    bat
    jq
    ripgrep
    tree
    curl

    # Git tools
    git
    lazygit

    # Terminal tools
    zellij
    neofetch
    expect

    # Recording
    asciinema
    asciinema-agg

    # Database
    redli
  ];
}
