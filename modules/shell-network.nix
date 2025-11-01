# Network tools and utilities
# SSH, autossh, netcat, network diagnostics
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
  # Network Tools and Utilities
  # =============================================================================
  home.packages = with pkgs;
    [
      # Network tools
      autossh
      lazyssh
      inetutils
      netcat
      dig
    ]
    ++ lib.optionals isLinux [
      # Linux-specific network tools
      openssh
      multipass
    ];
}
