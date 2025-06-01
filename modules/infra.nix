{ pkgs, lib, isWsl, ... }: 

with pkgs;

{
  home.packages = with pkgs; [
    k6
    kubectl
    kubectx
    k9s
    stern
    kubernetes-helm
    kubectl-tree
  ] ++ lib.optionals (!isWsl) [
    minikube
    lazydocker
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
  ];

  # TODO : Activate only when isWsl == false
  # Initiate podman systemd service
  # systemd.user.services.podman = {
  #   enable = true;
  #   description = "Init Podman";
  #   wantedBy = [ "default.target" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     Environment = "PATH=${pkgs.podman}/bin:${pkgs.coreutils}/bin:/run/wrappers/bin";
  #     ExecStart = "${pkgs.minikube}/bin/minikube start --driver=podman";
  #     ExecStop = "${pkgs.minikube}/bin/minikube stop";
  #     RemainAfterExit = true;
  #   };
  # };

  # TODO : Activate only when isWsl == false
  # Initiate minikube systemd service
  # systemd.user.services.minikube = {
  #   enable = true;
  #   description = "Init Minikube Cluster";
  #   wantedBy = [ "default.target" ];
  #   after = [ "podman.socket" ];
  #   requires = [ "podman.socket" ];
  #   serviceConfig = {
  #     Type = "simple";
  #     Environment = "PATH=${pkgs.podman}/bin:${pkgs.coreutils}/bin:/run/wrappers/bin";
  #     ExecStart = "${pkgs.minikube}/bin/minikube start --driver=podman";
  #     ExecStop = "${pkgs.minikube}/bin/minikube stop";
  #     RemainAfterExit = true;
  #   };
  # };
}

