{
  config,
  lib,
  pkgs,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  home.packages = with pkgs;
    [
      k6
      kubectl
      kubectx
      k9s
      stern
      kubernetes-helm
      kubectl-tree
      oxker
    ]
    ++ lib.optionals (isDarwin || (isLinux && !isWsl)) [
      dive
      minikube
      podman
      podman-compose
      podman-desktop
      vagrant
    ];

  # Podman Desktop configuration
  home.file = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    ".local/share/containers/podman-desktop/configuration/settings.json".text = builtins.toJSON {
      "podman.binary.path" = "${config.home.homeDirectory}/.nix-profile/bin/podman";
    };
  };

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
