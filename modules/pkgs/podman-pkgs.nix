{ pkgs, lib, ... }: {

  # Configure Podman setting
  home.activation.configSocket = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Enable podman.socket
    if [ -S "$XDG_RUNTIME_DIR/podman/podman.socket" ]; then
      nohup podman system service --time=0 > ~/.podman-service.log 2>&1 &
      echo $! > ~/.podman-service.pid
    fi
  '';

  # Configure shared mount
  home.activation.configSharedMount = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -S "findmnt -o TARGET,PROPAGATION / | grep shared" ]; then
      sudo mount --make-rshared /
    fi
  '';

  # Configure cgroup
  home.file.".config/containers/containers.conf".text = ''
    [engine]
    cgroup_manager = "cgroupfs"
  '';

  # Configure volume policy
  home.file.".config/containers/policy.json".text = ''
    {
      "default": [
        {
          "type": "insecureAcceptAnything"
        }
      ],
      "transports": {
        "docker-daemon": {
          "": [
            {
              "type": "insecureAcceptAnything"
            }
          ]
        }
      }
    }
  '';

  # Configure DOCKER_HOST
  home.activation.configDockerHost = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
  '';

  home.packages = with pkgs; [
    qemu # required for `podman machine init`
    virtiofsd # required for `podman machine init`
    crun # required for OCI runtime
    runc # required for OCI runtime
    podman-tui
    dive
    podman
    podman-compose
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
  };
}
