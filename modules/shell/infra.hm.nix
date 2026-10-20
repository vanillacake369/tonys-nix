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
      # AWS 전체 리소스 제어
      awscli2
      # SSH 키 없이 EC2 서버 보안 원격 접속
      ssm-session-manager-plugin
      # AWS 액세스 키 로컬 금고 키체인에 암호화 보관
      aws-vault
      # 여러 AWS 계정·세션 브라우저 탭별로 동시 전환
      granted

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
      lazyssh

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
