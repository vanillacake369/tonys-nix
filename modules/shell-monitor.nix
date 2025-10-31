# Monitoring and debugging tools
# System monitoring, process debugging, performance analysis
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
  # Monitoring and Debugging Tools
  # =============================================================================
  home.packages = with pkgs;
    [
      # Process monitoring
      htop
      btop

      # Monitoring and debugging
      lsof
      gdb
      smartmontools
    ]
    ++ lib.optionals isLinux [
      # Linux-specific debugging tools
      psmisc
      strace
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      wayland-utils
    ];
}
