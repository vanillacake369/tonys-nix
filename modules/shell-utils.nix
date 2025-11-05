# General CLI utilities and tools
# Core utilities, terminal tools, recording, database clients, platform-specific services
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
  home.packages = with pkgs;
    [
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
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      google-authenticator
    ]
    ++ lib.optionals isLinux [
      # Linux-specific tools
      xclip
    ];
}
