# Monitoring and debugging tools
# System monitoring, process debugging, performance analysis
{
  pkgs,
  lib,
  isWsl,
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

      # Storage monitoring
      dust
      ncdu

      # Monitoring and debugging
      lsof
      smartmontools
    ]
    ++ lib.optionals isLinux [
      # Linux-specific debugging tools
      gdb # GDB has build issues on macOS and lldb is preferred there anyway
      psmisc
      strace
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      wayland-utils
    ];
}
