# General CLI utilities and tools
# Core utilities, terminal tools, recording, database clients, platform-specific services
{
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
      moreutils
      ripgrep
      fd
      tree
      curl
      httpie
      openssl

      # Terminal tools
      fastfetch
      expect

      # Recording
      asciinema
      asciinema-agg
      vhs
      ffmpeg

      # Database
      redli

      # Secrets
      sops
      age
      ssh-to-age
      gnupg

      # Monitoring and debugging
      htop
      btop
      dust
      ncdu
      lsof
      smartmontools
    ]
    ++ lib.optionals isDarwin [
      # Mac-specific tools
      pngpaste
      terminal-notifier
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      google-authenticator
      wayland-utils
    ]
    ++ lib.optionals isLinux [
      # Linux-specific tools
      # GDB has build issues on macOS and lldb is preferred there anyway
      xclip
      gdb
      psmisc
      strace
    ];
}
