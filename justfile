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
SYSTEM_ARCH := `bash -euo pipefail -c '       \
  if [[ "$(uname -s)" == "Darwin" ]]; then    \
    if [[ "$(uname -m)" == "arm64" ]]; then   \
      echo aarch64-darwin;                    \
    else                                      \
      echo x86_64-darwin;                     \
    fi                                        \
  elif [[ "$(uname -s)" == "Linux" ]]; then  \
    if [[ "$(uname -m)" == "aarch64" ]]; then \
      echo aarch64-linux;                     \
    else                                      \
      echo x86_64-linux;                      \
    fi                                        \
  else                                        \
    echo unsupported;                         \
  fi'`




########### *** INSTALLATION *** ##########

# Initiate all configuration
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
  #!/usr/bin/env bash
  homeManager=$(command -v home-manager 2>/dev/null)

  if [ -z "$homeManager" ]; then
    echo "[!] Installing Home Manager"
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
    # Command below has already inside of ~/.zshrc, so no worries :-)
    # . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
  else
    echo "[✓] Home Manager installed already"
  fi

# Enable uidmap
install-uidmap:
  #!/usr/bin/env bash
  if ! command -v newuidmap >/dev/null || ! command -v newgidmap >/dev/null; then
    echo "[!] installing uidmap via apt (requires sudo)"
    sudo apt update && sudo apt install -y uidmap
  else
    echo "[✓] newuidmap and newgidmap already exist"
  fi

# Install packages by nix home-manager
# If nixos, it'll run nixos-rebuild & home-manager
install-pckgs *HM_CONFIG=SYSTEM_ARCH:
  #!/usr/bin/env bash
  echo "OS_TYPE={{OS_TYPE}}, HM_CONFIG={{HM_CONFIG}}, HOSTNAME={{HOSTNAME}}"
  
  if [[ "{{OS_TYPE}}" == "nixos" ]]; then
    sudo nixos-rebuild switch --flake .#{{HOSTNAME}}
  fi
  
  case "{{HM_CONFIG}}" in
    "x86_64-linux"|"aarch64-linux"|"x86_64-darwin"|"aarch64-darwin")
      if [[ "{{OS_TYPE}}" == "wsl" ]]; then
        echo "Running: home-manager switch --flake .#hm-wsl-{{HM_CONFIG}} -b back"
        home-manager switch --flake .#hm-wsl-{{HM_CONFIG}} -b back
      else
        echo "Running: home-manager switch --flake .#hm-{{HM_CONFIG}} -b back"
        home-manager switch --flake .#hm-{{HM_CONFIG}} -b back
      fi
      ;;
    "unsupported")
      echo "[!] Unsupported system architecture. Please manually specify config"
      exit 1
      ;;
    *)
      if [[ "{{OS_TYPE}}" == "wsl" ]]; then
        echo "[!] Unknown system architecture: {{HM_CONFIG}}. Trying WSL config anyway..."
        home-manager switch --flake .#hm-wsl-{{HM_CONFIG}} -b back
      else
        echo "[!] Unknown system architecture: {{HM_CONFIG}}. Trying anyway..."
        home-manager switch --flake .#hm-{{HM_CONFIG}} -b back
      fi
      ;;
  esac

# Apply zsh
apply-zsh:
  #!/usr/bin/env bash
  if ! grep -qx "/home/{{USERNAME}}/.nix-profile/bin/zsh" /etc/shells; then
    echo "/home/{{USERNAME}}/.nix-profile/bin/zsh" | sudo tee -a /etc/shells
  fi
  chsh -s /home/{{USERNAME}}/.nix-profile/bin/zsh



########### *** CLEANER *** ##########

# Clean redundant packages by nix gc
clean:
  #!/usr/bin/env bash
  nix-collect-garbage -d
  # if not wsl, gc for nixos
  if ! grep -qi Microsoft /proc/version 2>/dev/null; then
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
    sudo mount --make-rshared /
    echo "[✓] shared mount configured for podman"
  else
    echo "[✓] shared mount already configured for podman"
  fi
