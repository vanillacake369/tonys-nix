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

      /*
      Cloud tools
      */
      awscli
      # ssm-session-manager-plugin

      /*
      Testing tools
      */
      # k6
      nuclei

      /*
      Infrastructure tools
      */
      # kubectl
      # kubectx
      # k9s
      # kubernetes-helm
      # kubectl-tree
      # ngrok
      # terraform

      /*
      Networking tools
      */
      v2ray
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
