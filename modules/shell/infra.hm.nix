# Infrastructure and DevOps tools
{
  pkgs,
  lib,
  isDarwin,
  ...
}: {
  # =============================================================================
  # Infrastructure and DevOps Packages
  # =============================================================================
  home.packages = with pkgs;
    lib.optionals isDarwin [
      /*
      Docker TUI
      */
      # lazydocker
      podman-tui

      /*
      Cloud tools
      */
      # awscli
      # ssm-session-manager-plugin

      /*
      Testing tools
      */
      # k6
      nuclei

      /*
      Kubernetes tools
      */
      kubectl
      # kubectx
      # k9s
      # kubectl-tree
      # ngrok
      kubernetes-helm
      kustomize
      kubeconform
      kube-linter
      kube-score
      kube-state-metrics
      kubectl-ai
      skaffold
      gitleaks
      crane
      buildah
      skopeo

      /*
      Infrastructure tools
      */
      conftest
      trivy
      actionlint
      shellcheck

      /*
      Networking tools
      */
      # v2ray
    ]
    ++ lib.optionals isDarwin [
      /*
      MacOS-specific tools
      */
      # minikube
      # podman
      # podman-compose
      # podman-desktop
      # qemu
    ];
}
