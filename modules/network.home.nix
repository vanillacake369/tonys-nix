# Network tools and utilities
# SSH, autossh, netcat, network diagnostics
{
  pkgs,
  lib,
  isLinux,
  isDarwin,
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

      # Wireguard
      wireguard-go
    ]
    ++ lib.optionals isDarwin [
      iproute2mac # darwin-only (macOS `ip` shim)
    ]
    ++ lib.optionals isLinux [
      # Linux-specific network tools
      openssh
    ];
}
