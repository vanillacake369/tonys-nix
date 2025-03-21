{ pkgs, lib, ... }: {

  # Configure Podman setting
  home.activation.configPodman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    echo "$XDG_RUNTIME_DIR/podman"
    if [ -d "$XDG_RUNTIME_DIR/podman" ]; then
      nohup podman system service --time=0 > ~/.podman-service.log 2>&1 &
      echo $! > ~/.podman-service.pid
    fi
  '';

  home.packages = with pkgs; [
    qemu # required for `podman machine init`
    virtiofsd # required for `podman machine init`
    crun # required for OCI runtime
    runc # required for OCI runtime
    podman-tui
    dive
    # podman
    podman-compose
  ];

  programs.podman = {
    enable = true;
    dockerCompat = true;
  };

  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
  };
}

