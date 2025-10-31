# Platform-specific services and configurations
# Systemd services, Podman, Vagrant, session variables
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
  # Platform-Specific Service Packages
  # =============================================================================
  home.packages = with pkgs;
    lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      google-authenticator
    ]
    ++ lib.optionals isLinux [
      # Linux-specific tools
      xclip
    ];

  # =============================================================================
  # Multipass Daemon Service (Linux only)
  # =============================================================================
  systemd.user.services.multipassd = lib.mkIf isLinux {
    Unit = {
      Description = "Multipass VM manager daemon";
      After = ["network.target"];
    };

    Service = {
      Type = "simple";
      RemainAfterExit = true;
      TimeoutStartSec = 600;
      ExecStart = "${pkgs.multipass}/bin/multipassd";
      Restart = "on-failure";
      RestartSec = 5;
      StandardOutput = "journal";
      StandardError = "journal";
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  # =============================================================================
  # Podman Desktop Configuration (macOS and native Linux)
  # =============================================================================
  home.file = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    ".local/share/containers/podman-desktop/configuration/settings.json".text = builtins.toJSON {
      "podman.binary.path" = "${config.home.homeDirectory}/.nix-profile/bin/podman";
    };
  };

  # =============================================================================
  # Vagrant with QEMU Configuration (macOS and native Linux)
  # =============================================================================
  home.sessionVariables = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    VAGRANT_QEMU_DIR = "${pkgs.qemu}/share/qemu";
    VAGRANT_DEFAULT_PROVIDER = "qemu";
  };
}
