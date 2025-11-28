########### *** GLOBAL VARIABLE *** ##########
# Env of user, host, os
USERNAME := `whoami`
HOSTNAME := `hostname`
OS_TYPE := `bash -euo pipefail -c '           \
  if [[ -d /etc/nixos ]]; then                \
    echo nixos;                               \
  elif [[ "$(uname -s)" == "Darwin" ]]; then  \
    echo darwin;                              \
  elif grep -qiE "(Microsoft|WSL)" /proc/version; then \
    echo wsl;                                 \
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

# Smart Garbage Collection Configuration
GC_SIZE_THRESHOLD_GB := "10"           # Trigger GC when store > 10GB
GC_MIN_INTERVAL_DAYS := "3"            # Minimum days between GC runs
GC_MAX_INTERVAL_DAYS := "14"           # Force GC after 14 days regardless
GC_STATE_FILE := ".nix-gc-state"       # Track last GC timestamp

# macOS Power Schedule Configuration
MAC_SLEEP_TIME := "02:00:00"           # Sleep time (HH:MM:SS)
MAC_WAKE_TIME := "06:30:00"            # Wake time (HH:MM:SS)
MAC_SCHEDULE_DAYS := "MTWRFSU"         # Days of week (M=Mon, T=Tue, W=Wed, R=Thu, F=Fri, S=Sat, U=Sun)




########### *** INSTALLATION *** ##########

# Initiate all configuration
install-all: install-nix link-nix-conf install-home-manager (install-uidmap-conditional) install-pckgs setup-mac-power-schedule smart-clean

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

# Enable uidmap (Linux only)
install-uidmap:
  #!/usr/bin/env bash
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "[!] uidmap installation skipped - not supported on $(uname -s)"
    exit 0
  fi
  
  if ! command -v newuidmap >/dev/null || ! command -v newgidmap >/dev/null; then
    echo "[!] installing uidmap via apt (requires sudo)"
    sudo apt update && sudo apt install -y uidmap
  else
    echo "[✓] newuidmap and newgidmap already exist"
  fi

# Conditional uidmap install - only run on Linux
install-uidmap-conditional:
  #!/usr/bin/env bash
  if [[ "{{OS_TYPE}}" == "darwin" ]]; then
    echo "[✓] uidmap installation skipped on macOS"
  else
    just install-uidmap
  fi

# Install packages by nix home-manager
# If nixos, it'll run nixos-rebuild & home-manager
install-pckgs *HM_CONFIG=SYSTEM_ARCH:
  #!/usr/bin/env bash
  echo "OS_TYPE={{OS_TYPE}}, HM_CONFIG={{HM_CONFIG}}, HOSTNAME={{HOSTNAME}}"
  
  # Installation : NixOS
  if [[ "{{OS_TYPE}}" == "nixos" ]]; then
    # Validate hardware configuration for NixOS (stored in /etc/nixos/)
    echo "[!] Checking hardware configuration..."
    if [[ ! -f "/etc/nixos/hardware-configuration.nix" ]]; then
      echo "[!] /etc/nixos/hardware-configuration.nix not found. Generating for this machine..."
      sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
      echo "[✓] Generated /etc/nixos/hardware-configuration.nix"
    fi

    sudo nixos-rebuild switch --flake .#{{HOSTNAME}} --impure
  fi
  
  # Installation : Other distros
  case "{{HM_CONFIG}}" in
    "x86_64-linux"|"aarch64-linux"|"x86_64-darwin"|"aarch64-darwin")
      if [[ "{{OS_TYPE}}" == "wsl" ]]; then
        echo "Running: home-manager switch --flake .#hm-wsl-{{HM_CONFIG}} -b back"
        home-manager switch --flake .#hm-wsl-{{HM_CONFIG}} -b back
      elif [[ "{{OS_TYPE}}" == "nixos" ]]; then
        echo "Running: home-manager switch --flake .#hm-nixos-{{HM_CONFIG}} -b back"
        home-manager switch --flake .#hm-nixos-{{HM_CONFIG}} -b back
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
      elif [[ "{{OS_TYPE}}" == "nixos" ]]; then
        echo "[!] Unknown system architecture: {{HM_CONFIG}}. Trying NixOS config anyway..."
        home-manager switch --flake .#hm-nixos-{{HM_CONFIG}} -b back
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

# Setup macOS power schedule (macOS only)
setup-mac-power-schedule:
  #!/usr/bin/env bash
  if [[ "{{OS_TYPE}}" != "darwin" ]]; then
    echo "[✓] Power schedule setup skipped - not macOS"
    exit 0
  fi

  echo ""
  read -p "Do you want to configure automatic sleep schedule for macOS? ( yes(Y/y)/no(N/n) ): " -r confirm
  if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "[→] Power schedule setup skipped"
    exit 0
  fi
  echo ""

  echo "[!] Setting up macOS power schedule (requires sudo)..."

  # Clear any existing power schedules first
  sudo pmset repeat cancel >/dev/null 2>&1

  # Set both sleep and wake schedules in a single command
  # Format: pmset repeat sleep DAYS TIME wakeorpoweron DAYS TIME
  if sudo pmset repeat sleep {{MAC_SCHEDULE_DAYS}} {{MAC_SLEEP_TIME}} wakeorpoweron {{MAC_SCHEDULE_DAYS}} {{MAC_WAKE_TIME}}; then
    echo "[✓] Sleep schedule set: {{MAC_SLEEP_TIME}} daily"
    echo "[✓] Wake schedule set: {{MAC_WAKE_TIME}} daily"
  else
    echo "[✗] Failed to set power schedules"
    exit 1
  fi

  echo ""
  echo "[✓] Power schedule configured successfully!"
  echo ""
  echo "Schedule details:"
  echo "  • Sleep: {{MAC_SLEEP_TIME}} (every day)"
  echo "  • Wake:  {{MAC_WAKE_TIME}} (every day)"
  echo ""
  echo "To verify: sudo pmset -g sched"
  echo "To cancel: sudo pmset repeat cancel"

# Link nix.conf to system configuration
link-nix-conf:
  #!/usr/bin/env bash
  SOURCE_FILE="$(pwd)/dotfiles/nix/nix.conf"
  TARGET_FILE="/etc/nix/nix.conf"
  
  # Check if source exists
  if [[ ! -f "$SOURCE_FILE" ]]; then
    echo "[✗] Source file not found: $SOURCE_FILE"
    exit 1
  fi
  
  # Ensure /etc/nix directory exists
  if [[ ! -d "/etc/nix" ]]; then
    echo "[!] Creating /etc/nix directory (requires sudo)"
    sudo mkdir -p /etc/nix
  fi
  
  # Handle existing nix.conf
  if [[ -e "$TARGET_FILE" ]]; then
    if [[ -L "$TARGET_FILE" ]]; then
      CURRENT_TARGET=$(readlink "$TARGET_FILE")
      if [[ "$CURRENT_TARGET" == "$SOURCE_FILE" ]]; then
        echo "[✓] Symlink already correctly configured"
        exit 0
      else
        echo "[!] Removing existing symlink pointing to: $CURRENT_TARGET"
        sudo rm "$TARGET_FILE"
      fi
    else
      echo "[!] Backing up existing nix.conf to ${TARGET_FILE}.backup"
      sudo mv "$TARGET_FILE" "${TARGET_FILE}.backup"
    fi
  fi
  
  # Create symlink
  echo "[!] Creating symlink: $TARGET_FILE -> $SOURCE_FILE"
  sudo ln -s "$SOURCE_FILE" "$TARGET_FILE"
  
  if [[ -L "$TARGET_FILE" ]]; then
    echo "[✓] Successfully linked nix.conf"
  else
    echo "[✗] Failed to create symlink"
    exit 1
  fi



########### *** SMART GARBAGE COLLECTION *** ##########

# Record GC execution timestamp
record-gc-execution:
  #!/usr/bin/env bash
  date +%s > {{GC_STATE_FILE}}
  echo "[✓] GC execution recorded at $(date)"

########### *** CLEANER *** ##########

# Intelligent conditional garbage collection (SSD-optimized)
smart-clean:
  #!/usr/bin/env bash
  # Quick days check only - skip expensive size check for speed
  days_since_gc=999
  
  if [[ -f "{{GC_STATE_FILE}}" ]]; then
    last_gc=$(cat {{GC_STATE_FILE}} 2>/dev/null || echo "0")
    current=$(date +%s)
    if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
      days_since_gc=$(( (current - last_gc) / 86400 ))
    fi
  fi
  
  # Quick decision based on time only
  if (( days_since_gc >= {{GC_MAX_INTERVAL_DAYS}} )); then
    echo "[!] Running GC (${days_since_gc} days since last cleanup)..."
    nix-collect-garbage -d --delete-older-than 14d
    
    if [[ "{{OS_TYPE}}" == "nixos" ]]; then
      sudo -H nix-collect-garbage -d --delete-older-than 14d
    fi
    
    date +%s > {{GC_STATE_FILE}}
    echo "[✓] Garbage collection completed"
  elif (( days_since_gc < {{GC_MIN_INTERVAL_DAYS}} )); then
    echo "[→] GC skipped (${days_since_gc} days since last cleanup)"
    echo "    Use 'just force-clean' to force cleanup"
  else
    # Only check size if within the decision window (3-14 days)
    # Use df for quick filesystem check instead of du
    if [[ -d "/nix/store" ]]; then
      used_percent=$(df /nix/store 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
      if [[ "$used_percent" -gt 80 ]]; then
        echo "[!] Running GC (disk usage at ${used_percent}%)..."
        nix-collect-garbage -d --delete-older-than 14d
        
        if [[ "{{OS_TYPE}}" == "nixos" ]]; then
          sudo -H nix-collect-garbage -d --delete-older-than 14d
        fi
        
        date +%s > {{GC_STATE_FILE}}
        echo "[✓] Garbage collection completed"
      else
        echo "[→] GC skipped (${days_since_gc}d since cleanup, ${used_percent}% disk used)"
        echo "    Use 'just force-clean' to force cleanup"
      fi
    else
      echo "[→] GC skipped (${days_since_gc} days since last cleanup)"
    fi
  fi

# Force garbage collection regardless of conditions (manual override)
force-clean:
  #!/usr/bin/env bash
  echo "[!] Force running garbage collection (manual override)..."
  nix-collect-garbage -d --delete-older-than 14d
  
  if [[ "{{OS_TYPE}}" == "nixos" ]]; then
    echo "[!] Force running system-wide garbage collection..."
    sudo -H nix-collect-garbage -d --delete-older-than 14d
  fi
  
  just record-gc-execution
  echo "[✓] Forced garbage collection completed"

# Show comprehensive GC status and metrics
gc-status:
  #!/usr/bin/env bash
  echo "=== GARBAGE COLLECTION STATUS ==="
  echo "Current store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo "N/A")"

  # Calculate days since last GC
  if [[ -f "{{GC_STATE_FILE}}" ]]; then
    last_gc=$(cat {{GC_STATE_FILE}} 2>/dev/null || echo "0")
    current=$(date +%s)
    if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
      days_since_gc=$(( (current - last_gc) / 86400 ))
      echo "Days since last GC: $days_since_gc days"
    else
      echo "Days since last GC: Unknown (corrupted timestamp)"
    fi
  else
    echo "Days since last GC: Never"
  fi

  if [[ -d "/nix/store" ]]; then
    used_percent=$(df /nix/store 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
    echo "Disk usage: ${used_percent}%"
  fi

  echo ""
  echo "=== CONFIGURATION ==="
  echo "Size threshold: {{GC_SIZE_THRESHOLD_GB}}GB (legacy - using disk % now)"
  echo "Min interval: {{GC_MIN_INTERVAL_DAYS}} days"
  echo "Max interval: {{GC_MAX_INTERVAL_DAYS}} days"
  echo "State file: {{GC_STATE_FILE}}"
  echo ""
  echo "Commands:"
  echo "  just smart-clean   # Run intelligent cleanup"
  echo "  just force-clean   # Force cleanup regardless of conditions"

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

# Run comprehensive Nix performance analysis
performance-test:
  #!/usr/bin/env bash
  echo "=== NIX PERFORMANCE TEST RESULTS ==="
  echo "Timestamp: $(date)"
  echo ""
  
  echo "1. STORE METRICS:"
  echo "   Store size: $(du -sh /nix/store | cut -f1)"
  echo "   Store paths: $(find /nix/store -maxdepth 1 -type d | wc -l)"
  echo "   Disk usage: $(df -h /nix/store | tail -1 | awk '{print $3 "/" $2 " (" $5 " full)"}')"
  echo ""
  
  echo "2. CONFIGURATION STATUS:"
  echo "   Auto-optimise: $(grep "auto-optimise-store" /etc/nix/nix.conf | cut -d= -f2 | xargs)"
  echo "   Max jobs: $(grep "max-jobs" /etc/nix/nix.conf | cut -d= -f2 | xargs)"
  echo "   Cores: $(grep "cores" /etc/nix/nix.conf | cut -d= -f2 | xargs)"
  echo "   CPU cores available: $(nproc)"
  echo ""
  
  echo "3. BINARY CACHE STATUS:"
  echo "   Substituters:"
  grep "substituters" /etc/nix/nix.conf | cut -d= -f2 | tr ' ' '\n' | sed 's/^/     - /'
  echo ""
  
  echo "4. GARBAGE COLLECTION:"
  if systemctl is-enabled nix-gc.timer >/dev/null 2>&1; then
    echo "   GC Timer: $(systemctl is-enabled nix-gc.timer) ($(systemctl is-active nix-gc.timer))"
    echo "   GC Schedule: $(systemctl show nix-gc.timer | grep OnCalendar | cut -d= -f2)"
  else
    echo "   GC Timer: Not available via systemctl"
  fi
  echo ""
  
  echo "5. QUICK PERFORMANCE TEST:"
  echo "   Testing small package installation speed..."
  start_time=$(date +%s.%N)
  nix shell nixpkgs#hello --command hello >/dev/null 2>&1
  end_time=$(date +%s.%N)
  duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
  echo "   Hello world test: ${duration}s"
  echo ""
  
  echo "6. STORE OPTIMIZATION POTENTIAL:"
  echo "   Checking for duplicate store paths..."
  store_links=$(find /nix/store -type l | wc -l 2>/dev/null || echo "0")
  echo "   Symlinks in store: $store_links"
  echo ""

  echo "7. SMART GARBAGE COLLECTION:"
  gc_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "N/A")

  # Calculate days since last GC
  if [[ -f "{{GC_STATE_FILE}}" ]]; then
    last_gc=$(cat {{GC_STATE_FILE}} 2>/dev/null || echo "0")
    current=$(date +%s)
    if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
      gc_days=$(( (current - last_gc) / 86400 ))
    else
      gc_days="N/A"
    fi
  else
    gc_days="Never"
  fi

  echo "   Current store size: $gc_size"
  echo "   Days since last GC: $gc_days"
  echo "   GC interval: {{GC_MIN_INTERVAL_DAYS}}-{{GC_MAX_INTERVAL_DAYS}} days"

  if [[ -d "/nix/store" ]]; then
    used_percent=$(df /nix/store 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')
    echo "   Disk usage: ${used_percent}%"
    if [[ "$used_percent" -gt 80 ]] || [[ "$gc_days" =~ ^[0-9]+$ && "$gc_days" -ge {{GC_MAX_INTERVAL_DAYS}} ]]; then
      echo "   GC recommendation: ✓ Cleanup needed"
    else
      echo "   GC recommendation: → Store is clean"
    fi
  fi
  echo ""

  echo "=== END PERFORMANCE TEST ==="


########### *** IMAGE GENERATION *** ##########

# List available image formats with descriptions
list-image-formats:
  #!/usr/bin/env bash
  echo "Available image formats for {{SYSTEM_ARCH}}:"
  echo ""
  echo "Format        Description"
  echo "----------    -----------"
  echo "iso           Bootable ISO image for installation/live boot"
  echo "virtualbox    VirtualBox OVA image"
  echo "vmware        VMware VMDK image"
  echo "qcow          QEMU qcow image for KVM/libvirt"
  echo ""
  echo "Usage: just build-image <format>"
  echo ""
  echo "Note: For Docker containers, use official NixOS Docker images instead."

# Build specific image format for current architecture
build-image FORMAT:
  #!/usr/bin/env bash
  echo "[!] Building {{FORMAT}} image for {{SYSTEM_ARCH}}..."
  if ! nix build .#{{FORMAT}}; then
    echo "[✗] Failed to build {{FORMAT}} image"
    echo "    Run 'just list-image-formats' to see available formats"
    exit 1
  fi
  echo "[✓] Successfully built {{FORMAT}} image"
  echo "    Output: $(readlink result)"

# Build specific image format for specific architecture
build-image-arch FORMAT ARCH:
  #!/usr/bin/env bash
  echo "[!] Building {{FORMAT}} image for {{ARCH}}..."
  if ! nix build .#packages.{{ARCH}}.{{FORMAT}}; then
    echo "[✗] Failed to build {{FORMAT}} image for {{ARCH}}"
    echo "    Supported architectures: x86_64-linux, aarch64-linux"
    echo "    Run 'just list-image-formats' to see available formats"
    exit 1
  fi
  echo "[✓] Successfully built {{FORMAT}} image for {{ARCH}}"
  echo "    Output: $(readlink result)"

# Build all image formats for current architecture
build-all-images:
  #!/usr/bin/env bash
  echo "[!] Building all image formats for {{SYSTEM_ARCH}}..."
  formats=("iso" "virtualbox" "vmware" "qcow")
  failed=()
  
  for format in "${formats[@]}"; do
    echo "Building $format..."
    if nix build .#$format; then
      echo "[✓] $format built successfully"
    else
      echo "[✗] $format build failed"
      failed+=("$format")
    fi
    echo ""
  done
  
  if [ ${#failed[@]} -eq 0 ]; then
    echo "[✓] All image formats built successfully"
  else
    echo "[!] Some formats failed: ${failed[*]}"
    exit 1
  fi

# Show built images and their sizes
show-images:
  #!/usr/bin/env bash
  echo "Built images in ./result*:"
  echo ""
  ls -lh result* 2>/dev/null | awk '{print $9, $5}' | column -t || echo "No images found. Run 'just build-image <format>' first."
