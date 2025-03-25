{ pkgs, lib, ... }: {
  # Configure Minikube on podman
  home.activation.checkAndRunMinikube = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Enable podman.socket
    # Check if any profile uses Podman (suppressing stderr)
    if minikube profile list 2>/dev/null | grep -q podman; then
      echo "[✓] Minikube is running on Podman"
    else
      echo "[!] Minikube is not running on Podman or no profiles exist"
      minikube delete --all --purge
      minikube config set rootless true
      minikube start --driver=podman --container-runtime=containerd --force
    fi
  '';

  home.packages = with pkgs; [
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
    minikube
  ];
}

