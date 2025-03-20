{ pkgs, lib, ... }: {

  # Configure Podman setting
  home.activation.configPodman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # export XDG_RUNTIME_DIR="/run/user/$(id -u)"

    echo "Checking Podman socket at: $XDG_RUNTIME_DIR/podman/podman.sock"
    ls -l "$XDG_RUNTIME_DIR/podman/podman.sock" || echo "Socket not found"

    if [ ! -S "$XDG_RUNTIME_DIR/podman/podman.sock" ]; then
      echo "Starting Podman API service..."
      
      # Alternative to systemctl if unavailable
      nohup podman system service --time=0 > /dev/null 2>&1 &

      # Persist DOCKER_HOST for user sessions
      echo 'export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock' >> ~/.bashrc
      echo 'export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock' >> ~/.zshrc
    else
      echo "podman.socket is already running."
    fi
  '';

  home.packages = with pkgs; [
    qemu # required for `podman machine init`
    virtiofsd # required for `podman machine init`
    podman-tui
    dive
    podman
    podman-compose
  ];
}

