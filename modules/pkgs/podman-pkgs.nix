{ pkgs, lib, ... }: {

  # Configure Podman setting
  home.activation.configPodman = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    podman system service --time=0 &
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

