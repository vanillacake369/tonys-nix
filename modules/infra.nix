{
  config,
  lib,
  pkgs,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  home.packages = with pkgs;
    [
      k6
      kubectl
      kubectx
      k9s
      stern
      kubernetes-helm
      kubectl-tree
      ngrok
    ]
    ++ lib.optionals (isDarwin || (isLinux && !isWsl)) [
      dive
      minikube
      podman
      podman-compose
      podman-desktop
      nixos-24_11.vagrant
      qemu
    ];

  # Podman Desktop configuration
  home.file = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    ".local/share/containers/podman-desktop/configuration/settings.json".text = builtins.toJSON {
      "podman.binary.path" = "${config.home.homeDirectory}/.nix-profile/bin/podman";
    };
  };

  # Bind vagrant & qemu (only when they're installed)
  home.sessionVariables = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    # Tell vagrant-qemu where QEMU's shared data lives (from Nix)
    VAGRANT_QEMU_DIR = "${pkgs.qemu}/share/qemu";

    # Optional: make qemu the default so you don't need --provider=qemu
    VAGRANT_DEFAULT_PROVIDER = "qemu";
  };
}
