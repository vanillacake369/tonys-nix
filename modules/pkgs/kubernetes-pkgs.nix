{ pkgs, ... }: {

  home.packages = with pkgs; [
    # docker
    docker

    # kubernetes
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
  ];
}

