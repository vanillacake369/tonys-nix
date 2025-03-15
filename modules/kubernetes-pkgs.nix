{ pkgs, ... }: {
  home.packages = with pkgs; [
    # kubernetes
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
  ];
}

