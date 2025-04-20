{ pkgs, lib, ... }: {

  home.packages = with pkgs; [
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
    minikube
    kubernetes-helm
    lazydocker
  ];
}

