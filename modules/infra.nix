{ pkgs, ... }: {

  home.packages = with pkgs; [
    k6
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
    minikube
  ];
}

