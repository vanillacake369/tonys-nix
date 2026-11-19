# General CLI utilities and tools
{
  pkgs,
  lib,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  home.packages = with pkgs;
    [
      # File & Search
      bat
      fd
      ripgrep
      tree

      # Data Processing & Text
      dasel
      jq
      moreutils
      yq

      # Network & Web
      curl
      httpie
      openssl

      # Code Analysis & Linters
      actionlint
      ast-grep
      shellcheck
      yamllint

      # Benchmarking & Performance
      hyperfine
      time

      # System Monitoring & Disk
      btop
      dust
      fastfetch
      htop
      lsof
      ncdu
      smartmontools

      # Security & Secrets
      age
      gnupg
      sops
      ssh-to-age

      # Media & Terminal Recording
      asciinema
      asciinema-agg
      ffmpeg
      vhs

      # Database & Productivity
      expect
      jira-cli-go
      redli
      usql
    ]
    ++ lib.optionals isDarwin [
      # macOS-specific
      pngpaste
      terminal-notifier
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (excluding WSL)
      google-authenticator
      wayland-utils
    ]
    ++ lib.optionals isLinux [
      # Linux-specific (including WSL)
      # GDB has build issues on macOS
      # and lldb is preferred there anyway
      gdb
      perf
      semgrep
      psmisc
      strace
      xclip
    ];
}
