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
      moreutils # sponge for safe file writes
      ripgrep
      tree
      curl

      # Git tools
      # INFO : git 에 대해서는 ./shell-core.nix 를 확인할 것
      ghalint
      lazygit
      bfg-repo-cleaner

      # Terminal tools
      zellij
      neofetch
      expect

      # Recording
      asciinema
      asciinema-agg

      # Database
      redli

      # Secrets
      sops
      age
      ssh-to-age
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
