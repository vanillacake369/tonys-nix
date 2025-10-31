# Infrastructure and DevOps tools
# Kubernetes, Docker, Cloud CLI, IaC tools
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
  # Infrastructure and DevOps Packages
  # =============================================================================
  home.packages = with pkgs;
    [
      # Container tools
      lazydocker

      # Cloud tools
      awscli
      ssm-session-manager-plugin

      # Infrastructure tools
      k6
      kubectl
      kubectx
      k9s
      stern
      kubernetes-helm
      kubectl-tree
      ngrok
      terraform
    ]
    ++ lib.optionals isDarwin [
      # macOS-specific container tools
      dive
      minikube
      podman
      podman-compose
      podman-desktop
      nixos-24_11.vagrant
      qemu
    ];
}
