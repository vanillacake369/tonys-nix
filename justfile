set shell := ["bash", "-euo", "pipefail", "-c"]

########### Global Settings ##########

HOSTNAME := `hostname`
OS_TYPE := `case "$(uname -s)" in
  Darwin) echo darwin ;;
  Linux)
    if [[ -d /etc/nixos ]]; then
      echo nixos
    elif grep -qiE '(Microsoft|WSL)' /proc/version 2>/dev/null; then
      echo wsl
    else
      echo linux
    fi
    ;;
  *) echo unsupported ;;
esac`
SYSTEM_ARCH := `case "$(uname -s):$(uname -m)" in
  Darwin:arm64) echo aarch64-darwin ;;
  Darwin:*) echo x86_64-darwin ;;
  Linux:aarch64) echo aarch64-linux ;;
  Linux:x86_64) echo x86_64-linux ;;
  Linux:amd64) echo x86_64-linux ;;
  *) echo unsupported ;;
esac`
GC_MIN_INTERVAL_DAYS := "3"
GC_MAX_INTERVAL_DAYS := "14"
GC_DELETE_OLDER_THAN := "14d"
GC_STATE_FILE := ".nix-gc-state"
MAC_SLEEP_TIME := "02:00:00"
MAC_WAKE_TIME := "06:30:00"
MAC_SCHEDULE_DAYS := "MTWRFSU"
NIX_CONF_SOURCE := justfile_directory() + "/dotfiles/nix/nix.conf"
NIX_CONF_TARGET := "/etc/nix/nix.conf"
AEROSPACE_CONFIG_PATH := "dotfiles/aerospace/aerospace.toml"

########### Bootstrap ##########

# Full first-time setup for the current machine.
bootstrap:
    #!/usr/bin/env bash
    just install-nix
    just system-link-nix-conf
    just install-home-manager
    just bootstrap-uidmap
    just apply
    just gc

# Install Nix if it is not available.
install-nix:
    #!/usr/bin/env bash
    if command -v nix >/dev/null 2>&1; then
      echo "[✓] Nix is already installed"
      exit 0
    fi

    echo "[!] Installing Nix"
    sh <(curl -L https://nixos.org/nix/install) --daemon

# Prepare Home Manager. On fresh systems the real install happens via flake commands.
install-home-manager:
    #!/usr/bin/env bash
    if command -v home-manager >/dev/null 2>&1; then
      echo "[✓] Home Manager is already installed"
      exit 0
    fi

    echo "[!] Home Manager not found - it will be bootstrapped via flake on apply"
    if nix-channel --list 2>/dev/null | grep -q '^home-manager'; then
      echo "[!] Removing legacy home-manager channel"
      nix-channel --remove home-manager
    fi

# Install uidmap only where it is relevant.
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

# Apply the flake for the current platform.
apply target=SYSTEM_ARCH:
    #!/usr/bin/env bash
    echo "OS_TYPE={{ OS_TYPE }}, TARGET={{ target }}, HOSTNAME={{ HOSTNAME }}"
    just apply-validate "{{ target }}"
    just apply-system "{{ target }}"
    just apply-home "{{ target }}"
    just sync-local-integrations

# Validate platform and target before applying any configuration.
apply-validate target:
    #!/usr/bin/env bash
    case "{{ OS_TYPE }}" in
      nixos|wsl|darwin|linux)
    ;;
      *)
    echo "[✗] Unsupported platform: {{ OS_TYPE }}"
    exit 1
    ;;
    esac

    case "{{ target }}" in
      x86_64-linux|aarch64-linux|x86_64-darwin|aarch64-darwin)
    echo "[✓] Apply target validated: {{ target }}"
    ;;
      unsupported)
    echo "[✗] Unsupported system architecture"
    exit 1
    ;;
      *)
    echo "[!] Non-standard target requested: {{ target }}"
    ;;
    esac

# Apply system-level configuration for hosts that require it.
apply-system target:
    #!/usr/bin/env bash
    if [[ "{{ OS_TYPE }}" != "nixos" ]]; then
      echo "[→] System apply skipped - not NixOS"
      exit 0
    fi

    echo "[!] Checking NixOS hardware configuration"
    if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
      echo "[!] Generating /etc/nixos/hardware-configuration.nix"
      sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
      echo "[✓] Generated /etc/nixos/hardware-configuration.nix"
    fi

    echo "[!] Applying NixOS system configuration"
    sudo nixos-rebuild switch --flake .#"{{ HOSTNAME }}" --impure

# Apply the Home Manager profile for the requested target.
apply-home target:
    #!/usr/bin/env bash
    if command -v home-manager >/dev/null 2>&1; then
      hm_cmd=(home-manager)
    else
      echo "[!] Bootstrapping Home Manager via flake"
      hm_cmd=(nix run home-manager/master --)
    fi

    case "{{ OS_TYPE }}" in
      nixos)
    flake_target="hm-nixos-{{ target }}"
    ;;
      wsl)
    flake_target="hm-wsl-{{ target }}"
    ;;
      darwin|linux)
    flake_target="hm-{{ target }}"
    ;;
      *)
    echo "[✗] Unsupported platform for Home Manager apply: {{ OS_TYPE }}"
    exit 1
    ;;
    esac

    echo "[!] Applying Home Manager target: ${flake_target}"
    echo "Running: ${hm_cmd[*]} switch --flake .#${flake_target} -b back"
    "${hm_cmd[@]}" switch --flake ".#${flake_target}" -b back

# Sync local desktop integrations after configuration changes are applied.
sync-local-integrations:
    #!/usr/bin/env bash
    just apply-fish
    just reload-aerospace-if-needed
    just setup-mac-power-schedule

# Reload AeroSpace when its config changed in git and the local environment supports it.
reload-aerospace-if-needed:
    #!/usr/bin/env bash
    if [[ "{{ OS_TYPE }}" != "darwin" ]]; then
      echo "[→] AeroSpace reload skipped - not macOS"
      exit 0
    fi

    if ! command -v aerospace >/dev/null 2>&1; then
      echo "[→] AeroSpace reload skipped - aerospace is not installed"
      exit 0
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "[→] AeroSpace reload skipped - not in a git worktree"
      exit 0
    fi

    if [[ -z "$(git status --porcelain -- "{{ AEROSPACE_CONFIG_PATH }}")" ]]; then
      echo "[→] AeroSpace reload skipped - no git changes in {{ AEROSPACE_CONFIG_PATH }}"
      exit 0
    fi

    echo "[!] Reloading AeroSpace config"
    aerospace reload-config
    echo "[✓] AeroSpace config reloaded"

# Ensure the Nix-provided fish is registered as a login shell.
apply-fish:
    #!/usr/bin/env bash
    fish_path="$HOME/.nix-profile/bin/fish"
    if ! grep -qx "$fish_path" /etc/shells; then
      echo "[!] Adding $fish_path to /etc/shells (requires sudo)"
      echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    current_shell=""
    case "{{ OS_TYPE }}" in
      darwin)
        current_shell=$(dscl . -read "$HOME" UserShell | awk '{print $2}')
        ;;
      linux|wsl|nixos)
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        ;;
      *)
        current_shell="$SHELL"
        ;;
    esac

    if [[ "$current_shell" != "$fish_path" ]]; then
      echo "[!] Changing default shell to $fish_path (may ask for password)"
      chsh -s "$fish_path"
    else
      echo "[✓] fish is already the default shell"
    fi

########### System Configuration ##########

# Link the repository nix.conf into /etc/nix/nix.conf.
system-link-nix-conf:
    #!/usr/bin/env bash
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
    echo "[✓] nix.conf symlink already configured"
    exit 0
      fi

      echo "[!] Removing existing nix.conf symlink: $current_target"
      sudo rm "$target_file"
    elif [[ -e "$target_file" ]]; then
      echo "[!] Backing up existing nix.conf to ${target_file}.backup"
      sudo mv "$target_file" "${target_file}.backup"
    fi

    echo "[!] Linking $target_file -> $source_file"
    sudo ln -s "$source_file" "$target_file"
    echo "[✓] nix.conf linked successfully"

# Configure daily sleep and wake scheduling on macOS.
setup-mac-power-schedule:
    #!/usr/bin/env bash
    if [[ "{{ OS_TYPE }}" != "darwin" ]]; then
      echo "[✓] Power schedule setup skipped - not macOS"
      exit 0
    fi

    parse_pmset_time() {
      local line="$1"
      local time_part
      local hour
      local min
      local ampm

      time_part="$(grep -oE '[0-9]{1,2}:[0-9]{2}(AM|PM)' <<<"$line" | head -1 || true)"
      if [[ -z "$time_part" ]]; then
    return 0
      fi

      hour="$(cut -d: -f1 <<<"$time_part")"
      min="$(grep -oE '[0-9]+' <<<"$(cut -d: -f2 <<<"$time_part")")"
      ampm="$(grep -oE '(AM|PM)' <<<"$time_part")"

      if [[ "$ampm" == "PM" && "$hour" -ne 12 ]]; then
    hour=$((hour + 12))
      elif [[ "$ampm" == "AM" && "$hour" -eq 12 ]]; then
    hour=0
      fi

      printf "%02d:%02d:00" "$hour" "$min"
    }

    current_schedule="$(pmset -g sched 2>/dev/null || true)"
    repeating_section="$(sed -n '/Repeating power events:/,/Scheduled power events:/p' <<<"$current_schedule" || echo "$current_schedule")"

    sleep_line="$(grep -i 'sleep at' <<<"$repeating_section" || true)"
    wake_line="$(grep -iE '(wake|wakepoweron|wakeorpoweron).*at' <<<"$repeating_section" || true)"
    has_sleep="$(parse_pmset_time "$sleep_line")"
    has_wake="$(parse_pmset_time "$wake_line")"

    if [[ -n "$has_sleep" && -n "$has_wake" ]] && [[ "$has_sleep" == "{{ MAC_SLEEP_TIME }}" ]] && [[ "$has_wake" == "{{ MAC_WAKE_TIME }}" ]]; then
      echo "[✓] Power schedule already configured"
      echo "    Sleep: {{ MAC_SLEEP_TIME }} | Wake: {{ MAC_WAKE_TIME }}"
      exit 0
    fi

    if [[ -n "$has_sleep" || -n "$has_wake" ]]; then
      echo "[!] Current schedule detected"
      [[ -n "$has_sleep" ]] && echo "    Sleep: $has_sleep"
      [[ -n "$has_wake" ]] && echo "    Wake: $has_wake"
      echo "    New: sleep {{ MAC_SLEEP_TIME }} / wake {{ MAC_WAKE_TIME }}"
    else
      echo "[!] No existing macOS power schedule detected"
      echo "    New: sleep {{ MAC_SLEEP_TIME }} / wake {{ MAC_WAKE_TIME }}"
    fi

    read -r -p "Apply macOS power schedule? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "[→] Power schedule setup skipped"
      exit 0
    fi

    sudo pmset repeat cancel >/dev/null 2>&1 || true
    sudo pmset repeat sleep {{ MAC_SCHEDULE_DAYS }} {{ MAC_SLEEP_TIME }} wakeorpoweron {{ MAC_SCHEDULE_DAYS }} {{ MAC_WAKE_TIME }}

    echo "[✓] Power schedule configured"
    echo "    Verify: sudo pmset -g sched"
    echo "    Cancel: sudo pmset repeat cancel"

# Enable shared mount propagation for rootless Podman.
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

########### Maintenance ##########

# Persist a GC run timestamp.
gc-record:
    #!/usr/bin/env bash
    date +%s > {{ GC_STATE_FILE }}
    echo "[✓] GC execution recorded at $(date)"

# Run conditional garbage collection using age and disk pressure.
gc:
    #!/usr/bin/env bash
    days_since_gc=999

    if [[ -f "{{ GC_STATE_FILE }}" ]]; then
      last_gc="$(cat {{ GC_STATE_FILE }} 2>/dev/null || echo 0)"
      current="$(date +%s)"
      if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
    days_since_gc=$(((current - last_gc) / 86400))
      fi
    fi

    run_gc() {
      nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}
      if [[ "{{ OS_TYPE }}" == "nixos" ]]; then
    sudo -H nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}
      fi
      just gc-record
    }

    if (( days_since_gc >= {{ GC_MAX_INTERVAL_DAYS }} )); then
      echo "[!] Running GC (${days_since_gc} days since last cleanup)"
      run_gc
      exit 0
    fi

    if (( days_since_gc < {{ GC_MIN_INTERVAL_DAYS }} )); then
      echo "[→] GC skipped (${days_since_gc} days since last cleanup)"
      echo "    Use 'just gc-force' to force cleanup"
      exit 0
    fi

    if [[ ! -d /nix/store ]]; then
      echo "[→] GC skipped (/nix/store not found)"
      exit 0
    fi

    used_percent="$(df /nix/store 2>/dev/null | awk 'END {gsub(/%/, "", $5); print $5}')"
    if [[ -n "$used_percent" && "$used_percent" -gt 80 ]]; then
      echo "[!] Running GC (disk usage ${used_percent}%)"
      run_gc
    else
      echo "[→] GC skipped (${days_since_gc} days since cleanup, ${used_percent:-unknown}% disk used)"
      echo "    Use 'just gc-force' to force cleanup"
    fi

# Run garbage collection immediately.
gc-force:
    #!/usr/bin/env bash
    echo "[!] Force running garbage collection"
    nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}

    if [[ "{{ OS_TYPE }}" == "nixos" ]]; then
      echo "[!] Running system-wide garbage collection"
      sudo -H nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}
    fi

    echo "[!] Running nix store optimization"
    nix store optimise

    just gc-record
    echo "[✓] Forced garbage collection & store optimization completed"

# Show GC-related status for this machine.
gc-info:
    #!/usr/bin/env bash
    echo "=== Garbage Collection Status ==="
    echo "Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo N/A)"

    if [[ -f "{{ GC_STATE_FILE }}" ]]; then
      last_gc="$(cat {{ GC_STATE_FILE }} 2>/dev/null || echo 0)"
      current="$(date +%s)"
      if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
    echo "Days since last GC: $(((current - last_gc) / 86400))"
      else
    echo "Days since last GC: Unknown (corrupted state)"
      fi
    else
      echo "Days since last GC: Never"
    fi

    if [[ -d /nix/store ]]; then
      used_percent="$(df /nix/store 2>/dev/null | awk 'END {print $5}')"
      echo "Disk usage: ${used_percent:-N/A}"
    fi

    echo
    echo "Min interval: {{ GC_MIN_INTERVAL_DAYS }} days"
    echo "Max interval: {{ GC_MAX_INTERVAL_DAYS }} days"
    echo "Delete older than: {{ GC_DELETE_OLDER_THAN }}"
    echo "State file: {{ GC_STATE_FILE }}"

########### Diagnostics ##########

# Run a practical health check for this Nix setup.
performance-test:
    #!/usr/bin/env bash
    echo "=== Nix Performance Test ==="
    echo "Timestamp: $(date)"
    echo

    echo "1. Store metrics"
    echo "   Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo N/A)"
    echo "   Store paths: $(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    echo "   Disk usage: $(df -h /nix/store 2>/dev/null | awk 'END {print $3 \"/\" $2 \" (\" $5 \" full)\"}' || echo N/A)"
    echo

    echo "2. Nix configuration"
    echo "   Auto-optimise: $(grep 'auto-optimise-store' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | xargs || echo N/A)"
    echo "   Max jobs: $(grep 'max-jobs' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | xargs || echo N/A)"
    echo "   Cores: $(grep 'cores' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | xargs || echo N/A)"
    echo "   CPU cores available: $(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu 2>/dev/null || echo N/A)"
    echo

    echo "3. Binary cache"
    echo "   Substituters:"
    grep 'substituters' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | tr ' ' '\n' | sed 's/^/     - /' || true
    echo

    echo "4. Garbage collection"
    if command -v systemctl >/dev/null 2>&1 && systemctl is-enabled nix-gc.timer >/dev/null 2>&1; then
      echo "   GC Timer: $(systemctl is-enabled nix-gc.timer) ($(systemctl is-active nix-gc.timer))"
      echo "   GC Schedule: $(systemctl show nix-gc.timer | grep OnCalendar | cut -d= -f2)"
    else
      echo "   GC Timer: Not available via systemctl"
    fi
    echo

    echo "5. Quick shell test"
    start_time="$(date +%s.%N 2>/dev/null || date +%s)"
    nix shell nixpkgs#hello --command hello >/dev/null 2>&1 || true
    end_time="$(date +%s.%N 2>/dev/null || date +%s)"
    duration="$(echo "$end_time - $start_time" | bc 2>/dev/null || echo N/A)"
    echo "   hello test: ${duration}s"
    echo

    echo "6. Store optimization"
    echo "   Symlinks in store: $(find /nix/store -type l 2>/dev/null | wc -l | tr -d ' ')"
    echo

    echo "7. Smart GC summary"
    echo "   GC interval: {{ GC_MIN_INTERVAL_DAYS }}-{{ GC_MAX_INTERVAL_DAYS }} days"
    if [[ -d /nix/store ]]; then
      used_percent="$(df /nix/store 2>/dev/null | awk 'END {gsub(/%/, "", $5); print $5}')"
      echo "   Disk usage: ${used_percent}%"
      if [[ "$used_percent" -gt 80 ]]; then
    echo "   Recommendation: cleanup needed"
      else
    echo "   Recommendation: store is clean"
      fi
    fi

########### Images ##########

# List supported image outputs.
list-image-formats:
    #!/usr/bin/env bash
    echo "Available image formats for {{ SYSTEM_ARCH }}:"
    echo
    echo "Format        Description"
    echo "----------    -----------"
    echo "iso           Bootable ISO image"
    echo "virtualbox    VirtualBox OVA image"
    echo "vmware        VMware VMDK image"
    echo "qcow          QEMU qcow image"
    echo
    echo "Usage: just build-image <format>"
    echo "Note: For containers, use official NixOS Docker images instead."

# Build one image format for the current architecture.
build-image format:
    #!/usr/bin/env bash
    echo "[!] Building {{ format }} image for {{ SYSTEM_ARCH }}"
    nix build .#"{{ format }}"
    echo "[✓] Build complete: $(readlink result)"

# Build one image format for a specific architecture.
build-image-arch format arch:
    echo "[!] Building {{ format }} image for {{ arch }}"
    nix build .#packages."{{ arch }}"."{{ format }}"
    echo "[✓] Build complete: $(readlink result)"

# Build all supported image formats for the current architecture.
build-images:
    #!/usr/bin/env bash
    failed=()
    for format in iso virtualbox vmware qcow; do
      echo "[!] Building $format"
      if nix build ".#$format"; then
    echo "[✓] $format built successfully"
      else
    echo "[✗] $format build failed"
    failed+=("$format")
      fi
      echo
    done

    if [[ "${#failed[@]}" -gt 0 ]]; then
      echo "[✗] Failed formats: ${failed[*]}"
      exit 1
    fi

    echo "[✓] All image formats built successfully"

# Show local build artifacts produced by image builds.
show-images:
    #!/usr/bin/env bash
    echo "Built images in ./result*:"
    ls -lh result* 2>/dev/null | awk '{print $9, $5}' | column -t || echo "No images found. Run 'just build-image <format>' first."

########### Destructive / Legacy Cleanup ##########

# Uninstall Home Manager from the current profile.
uninstall-home-manager:
    #!/usr/bin/env bash
    echo y | home-manager uninstall

# Remove local editor and shell configs created by previous setups.
purge-local-configs:
    #!/usr/bin/env bash
    read -r -p "This removes local config directories and purges apt zsh. Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "[→] Purge cancelled"
      exit 0
    fi

    rm -rf ~/.config/nvim
    rm -rf ~/.local/share/nvim
    rm -rf ~/.cache/nvim
    rm -rf ~/.nix-profile/bin/spacevim
    rm -rf ~/.SpaceVim*
    rm -rf ~/.zshrc
    sudo apt-get --purge remove -y zsh
