{ pkgs, ... }: {

  home.packages = with pkgs; [
    k6
    kubernetes-helm    
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
    minikube
  ];
}

