########### *** GLOBAL VARIABLE *** ##########
# Env of user, host, os
USERNAME := `whoami`
HOSTNAME := `hostname`
OS_TYPE := `bash -euo pipefail -c '           \
  if [[ -d /etc/nixos ]]; then                \
    echo nixos;                               \
  elif grep -qiE "(Microsoft|WSL)" /proc/version; then \
    echo wsl;                                 \
  elif [[ "$(uname -s)" == "Darwin" ]]; then  \
    echo darwin;                              \
  else                                        \
    echo unsupported;                         \
  fi'`




########### *** INSTALLATION *** ##########

# Initiate all configration
install-all: install-nix install-home-manager install-uidmap install-pckgs clean

# Install nix
install-nix:
  #!/usr/bin/env bash
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

# Init packages of nixos
init-nixos:
  sudo nixos-rebuild switch --flake .#{{HOSTNAME}}

# Install packages by nix home-manager
install-pckgs *HM_CONFIG=OS_TYPE:
  home-manager switch --flake .#hm-{{HM_CONFIG}} -b back

# Apply zsh
apply-zsh:
  #!/usr/bin/env sh
  if ! grep -qx "/home/{{USERNAME}}/.nix-profile/bin/zsh" /etc/shells; then \
    echo "/home/{{USERNAME}}/.nix-profile/bin/zsh" | sudo tee -a /etc/shells; \
  fi
  chsh -s /home/{{USERNAME}}/.nix-profile/bin/zsh
  source ~/.zshrc



########### *** CLEANER *** ##########

# Clean redundant packages by nix gc
clean:
  #!/usr/bin/env sh
  nix-collect-garbage -d
  # if not wsl, gc for nixos
  if [[ ! $(grep -i Microsoft /proc/version) ]]; then
    sudo nix-collect-garbage -d
  fi

# Clear all dependencies
clear-all:
  echo y | home-manager uninstall

# Remove all previous configs
remove-configs:
  rm -rf ~/.config/nvim
  rm -rf ~/.local/share/nvim
  rm -rf ~/.cache/nvim
  rm -rf ~/.nix-profile/bin/spacevim
  rm -rf ~/.SpaceVim*
  rm -rf ~/.zshrc
  sudo apt-get --purge remove zsh 


########### *** APPLICATION *** ##########

# Enable shared mount for rootless podman
enable-shared-mount:
  #!/usr/bin/env bash
  PROPAGATION=$(findmnt -no PROPAGATION /)

  if [[ "$PROPAGATION" != *"shared"* ]]; then
    echo "[!] configuring shared mount for podman"
  else
    echo "[✓] shared mount already configured for podman"
  fi
