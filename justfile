# Run nix home-manager
setup-nix: remove-nvim remove-spacevim remove-zsh install-nix install-home-manager install-uidmap install clean apply-zsh enable-shared-mount


# Username of current shell
USERNAME := `whoami`


# Install nix
install-nix:
  #!/usr/bin/env sh
  nix=$(which nix)
  if [[ -z "$nix" ]]; then
    echo "[!] Installing Nix"
    # sh <(curl -L https://nixos.org/nix/install) --daemon
  else
    echo "[✓] Nix installed already"
  fi

  
# Install Home Manager
install-home-manager:
  #!/usr/bin/env sh
  homeManager=$(command -v home-manager 2>/dev/null)

  if [ -z "$homeManager" ]; then
    echo "[!] Installing Home Manager"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    # Command below has already inside of ~/.zshrc, so no worries :-)
    # . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  else
    echo "[✓] Home Manger installed already"
  fi

# Enable uidmap
install-uidmap:
  #!/usr/bin/env sh
  if ! command -v newuidmap >/dev/null || ! command -v newgidmap >/dev/null; then
    echo "[!] installing uidmap via apt (requires sudo)"
    sudo apt update && sudo apt install -y uidmap
  else
    echo "[✓] newuidmap and newgidmap already exist"
  fi

# Clear all dependencies
clear-all:
  echo y | home-manager uninstall

# Remove nvim
remove-nvim:
  rm -rf ~/.config/nvim
  rm -rf ~/.local/share/nvim
  rm -rf ~/.cache/nvim

# Remove spacevim
remove-spacevim:
  rm -rf ~/.nix-profile/bin/spacevim
  rm -rf ~/.SpaceVim*
  
# Remove zsh
remove-zsh:
  rm -rf ~/.zshrc
  sudo apt-get --purge remove zsh 

# Install packages by nix home-manager
install:
  home-manager switch --flake .#{{USERNAME}} -b back

# Clean redundant packages by nix gc
clean:
  nix-collect-garbage -d

# Apply zsh
apply-zsh:
  exec zsh
  chsh -s /home/#{{USERNAME}}/.nix-profile/bin/zsh

# Enable shared mount for rootless podman
enable-shared-mount:
  #!/usr/bin/env bash
  PROPAGATION=$(findmnt -no PROPAGATION /)

  if [[ "$PROPAGATION" != *"shared"* ]]; then
    echo "[!] configuring shared mount for podman"
  else
    echo "[✓] shared mount already configured for podman"
  fi

# Minikube on podman
run-minikube:
  #!/usr/bin/env sh
  if minikube profile list 2>/dev/null | grep -q podman; then
    echo "[✓] Minikube is running on Podman"
  else
    echo "[!] Minikube is not running on Podman or no profiles exist"
    sudo podman volume rm minikube
    minikube delete --all --purge
    sudo mount --make-rshared /
    minikube config set rootless true
    minikube start --driver=podman --container-runtime=containerd --force
  fi


driver := `minikube profile list -o json | jq -r '.valid[] | select(.Name == "minikube") | .Config.Driver'`
active := `minikube profile list -o json | jq -r '.valid[] | select(.Name == "minikube") | .Active'`
active_kube_context := `minikube profile list -o json | jq -r '.valid[] | select(.Name == "minikube") | .ActiveKubeContext'`
is_podman_driver := if driver == "podman" { "Yes"} else {"No"}

check-vars:
    @echo "Driver: {{driver}}"
    @echo "Active: {{active}}"
    @echo "ActiveKubeContext: {{active_kube_context}}"
    @echo "{{is_podman_driver}}"
