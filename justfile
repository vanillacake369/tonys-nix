# Install pckgs
install-pckgs: install clean apply-zsh

# Username of current shell
USERNAME := `whoami`
HOSTNAME := `hostname`

# Install nix
install-nix:
  #!/usr/bin/env sh
  nix=$(which nix)
  if [[ -z "$nix" ]]; then
    echo "[!] Installing Nix"
    sh <(curl -L https://nixos.org/nix/install) --daemon
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
    nix-shell '<home-manager>' -A install
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

# Init packages of nixos
init-nixos:
  sudo nixos-rebuild switch --flake .#{{HOSTNAME}}

# Install packages by nix home-manager
install:
  home-manager switch --flake .#{{USERNAME}} -b back

# Clean redundant packages by nix gc
clean:
  nix-collect-garbage -d

# Apply zsh
apply-zsh:
  #!/usr/bin/env sh
  if ! grep -qx "/home/{{USERNAME}}/.nix-profile/bin/zsh" /etc/shells; then \
    echo "/home/{{USERNAME}}/.nix-profile/bin/zsh" | sudo tee -a /etc/shells; \
  fi
  chsh -s /home/{{USERNAME}}/.nix-profile/bin/zsh
  source ~/.zshrc

# Enable shared mount for rootless podman
enable-shared-mount:
  #!/usr/bin/env bash
  PROPAGATION=$(findmnt -no PROPAGATION /)

  if [[ "$PROPAGATION" != *"shared"* ]]; then
    echo "[!] configuring shared mount for podman"
  else
    echo "[✓] shared mount already configured for podman"
  fi

# Status of minikube on podman
driver := `minikube profile list -o json | jq -r '.valid[] | select(.Name == "minikube") | .Config.Driver'`
active := `minikube profile list -o json | jq -r '.valid[] | select(.Name == "minikube") | .Active'`
active_kube_context := `minikube profile list -o json | jq -r '.valid[] | select(.Name == "minikube") | .ActiveKubeContext'`

# Run minikube on podman
run-minikube:
  #!/usr/bin/env lua

  function isDriverPodman(driver)
    local stripedDriver = driver:gsub("%s+", "")
    return stripedDriver == "podman"
  end
  function isActive(active)
    return active == true
  end
  function isActiveKubeContext(kubeContext)
    return kubeContext == true
  end
  
  local isValidStatus = isDriverPodman( "{{driver}}" ) and isActive( {{active}} ) and isActiveKubeContext( {{active_kube_context}} )
  if isValidStatus then
    print("[✓] Minikube is running on Podman")
  else
    print("[!] Minikube is not running on Podman or not in active context")
    os.execute('podman volume rm minikube')
    os.execute('minikube delete --all --purge')
    os.execute('sudo mount --make-rshared /')
    os.execute('minikube config set rootless true')
    os.execute('minikube start --driver=podman --container-runtime=containerd --force')
  end
