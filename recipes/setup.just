NIX_CONF_SOURCE := justfile_directory() + "/dotfiles/nix/nix.conf"
NIX_CONF_TARGET := "/etc/nix/nix.conf"

# Set up this machine. Actions: all, nix, home, mac, completions.
setup action:
    #!/usr/bin/env bash
    case {{ quote(action) }} in
      all) just bootstrap ;;
      nix) just install-nix && just system-link-nix-conf ;;
      home) just install-home-manager && just apply home ;;
      mac) just sync-local-integrations ;;
      completions) just _setup-completions ;;
      *) echo "[x] Expected: just setup {all|nix|home|mac|completions}" >&2; exit 2 ;;
    esac

# Full first-time setup for the current machine.
[private]
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail
    just install-nix
    just system-link-nix-conf
    just install-home-manager
    just bootstrap-uidmap
    just apply
    just gc

# Prepare the minimum runtime needed for checks and apply on a plain machine.
[private]
_bootstrap-core:
    #!/usr/bin/env bash
    set -euo pipefail
    just install-nix
    just system-link-nix-conf
    just install-home-manager

# Install Nix if it is not available.
[private]
install-nix:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v nix >/dev/null 2>&1; then
      echo "[✓] nix"
      exit 0
    fi

    echo "[→] Installing Nix"
    sh <(curl -L https://nixos.org/nix/install) --daemon
    echo "[✓] nix installed"

# Prepare Home Manager. On fresh systems the real install happens via flake commands.
[private]
install-home-manager:
    #!/usr/bin/env bash
    if command -v home-manager >/dev/null 2>&1; then
      echo "[✓] home-manager"
      exit 0
    fi

    echo "[→] home-manager via flake"
    if nix-channel --list 2>/dev/null | grep -q '^home-manager'; then
      echo "[!] Removing legacy home-manager channel"
      nix-channel --remove home-manager
    fi

# Install uidmap only where it is relevant.
[private]
bootstrap-uidmap:
    #!/usr/bin/env bash
    case "{{ OS_TYPE }}" in
      darwin)
    echo "[✓] uidmap install skipped on macOS"
    ;;
      linux|wsl)
    just install-uidmap
    ;;
      nixos)
    echo "[✓] uidmap install skipped on NixOS"
    ;;
      *)
    echo "[→] uidmap install skipped on unsupported platform: {{ OS_TYPE }}"
    ;;
    esac

# Install uidmap on Debian/Ubuntu style Linux hosts.
[private]
install-uidmap:
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Linux" ]]; then
      echo "[→] uidmap install skipped on $(uname -s)"
      exit 0
    fi

    if command -v newuidmap >/dev/null 2>&1 && command -v newgidmap >/dev/null 2>&1; then
      echo "[✓] newuidmap and newgidmap already exist"
      exit 0
    fi

    echo "[!] Installing uidmap via apt (requires sudo)"
    sudo apt update
    sudo apt install -y uidmap

# Link the repository nix.conf into /etc/nix/nix.conf.
[private]
system-link-nix-conf:
    #!/usr/bin/env bash
    set -euo pipefail
    source_file="{{ NIX_CONF_SOURCE }}"
    target_file="{{ NIX_CONF_TARGET }}"

    if [[ ! -f "$source_file" ]]; then
      echo "[✗] Source file not found: $source_file"
      exit 1
    fi

    if [[ ! -d /etc/nix ]]; then
      echo "[!] Creating /etc/nix (requires sudo)"
      sudo mkdir -p /etc/nix
    fi

    if [[ -L "$target_file" ]]; then
      current_target=$(readlink "$target_file")
      if [[ "$current_target" == "$source_file" ]]; then
    echo "[✓] nix.conf"
    exit 0
      fi

      echo "[!] Removing existing nix.conf symlink: $current_target"
      sudo rm "$target_file"
    elif [[ -e "$target_file" ]]; then
      echo "[!] Backing up existing nix.conf to ${target_file}.backup"
      sudo mv "$target_file" "${target_file}.backup"
    fi

    echo "[→] Linking nix.conf"
    sudo ln -s "$source_file" "$target_file"
    echo "[✓] nix.conf"

# Enable shared mount propagation for rootless Podman.
[private]
enable-shared-mount:
    #!/usr/bin/env bash
    propagation="$(findmnt -no PROPAGATION /)"
    if [[ "$propagation" == *shared* ]]; then
      echo "[✓] Shared mount propagation is already configured"
      exit 0
    fi

    echo "[!] Configuring shared mount propagation for Podman"
    sudo mount --make-rshared /
    echo "[✓] Shared mount propagation configured"

# Install only Just's Fish completion; do not activate the Home Manager profile.
[private]
_setup-completions:
    #!/usr/bin/env bash
    source_file="{{ justfile_directory() }}/completions/just-tonys-nix.fish"
    completion="$HOME/.config/fish/completions/just.fish"
    mkdir -p "$(dirname "$completion")"
    candidate="$(mktemp "${completion}.tmp.XXXXXX")"
    trap 'rm -f "$candidate"' EXIT
    cp "$source_file" "$candidate"

    if [[ -f "$completion" ]] && cmp -s "$candidate" "$completion"; then
      echo "[✓] Just Fish completion is already up to date: $completion"
    else
      chmod 0644 "$candidate"
      mv -f "$candidate" "$completion"
      echo "[✓] Installed Just Fish completion: $completion"
    fi
    echo "    tonys-nix candidates activate only inside this repository."
