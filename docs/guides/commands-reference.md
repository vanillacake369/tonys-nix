# Commands Reference

Complete reference for all justfile commands available in this repository.

## Table of Contents

- [Primary Workflow](#primary-workflow)
- [Individual Installation Steps](#individual-installation-steps)
- [System-Specific Configurations](#system-specific-configurations)
- [Maintenance and Cleanup](#maintenance-and-cleanup)
- [Development Connections](#development-connections)
- [Image Generation](#image-generation)
- [Manual Home-Manager Operations](#manual-home-manager-operations)

---

## Primary Workflow

These are the recommended commands for daily use:

### `just install-all`

**Description**: Complete installation pipeline (nix, home-manager, packages)

**What it does**:
1. Installs Nix package manager if not present
2. Installs home-manager
3. Installs uidmap for containers (Linux only)
4. Installs all packages via home-manager
5. Sets up macOS power schedule (macOS only, interactive)
6. Runs intelligent cleanup (smart-clean)

**Usage**:
```bash
just install-all
```

**When to use**:
- Initial setup on a new machine
- Complete system refresh
- After major configuration changes

---

### `just install-pckgs`

**Description**: Install packages using home-manager (auto-detects system)

**What it does**:
- Automatically detects your OS and architecture
- Applies appropriate home-manager configuration
- Syncs dotfiles and configurations
- Updates Claude Code configuration

**Usage**:
```bash
# Auto-detect system
just install-pckgs

# Specify architecture manually
just install-pckgs x86_64-linux
just install-pckgs aarch64-darwin
```

**Supported architectures**:
- `x86_64-linux` - 64-bit Linux
- `aarch64-linux` - ARM64 Linux
- `x86_64-darwin` - Intel macOS
- `aarch64-darwin` - Apple Silicon macOS

**When to use**:
- After modifying any configuration files
- To update packages
- To apply dotfile changes

---

### `just smart-clean`

**Description**: Intelligent SSD-optimized garbage collection (skips when not needed)

**What it does**:
- Checks days since last cleanup and disk usage
- Only runs GC if store > 10GB OR > 14 days since last cleanup
- Reduces SSD wear by 80-90%
- Records cleanup timestamp

**Usage**:
```bash
just smart-clean
```

**Decision logic**:
- **Runs GC if**: Days ≥ 14 OR disk usage > 80%
- **Skips GC if**: Days < 3
- **Checks size if**: 3 ≤ days < 14

**When to use**:
- Included in `install-all` pipeline
- Run manually when experiencing performance issues
- Part of regular maintenance routine

---

## Individual Installation Steps

These commands are for manual step-by-step installation:

### `just install-nix`

**Description**: Install Nix package manager

**What it does**:
- Checks if Nix is already installed
- Installs Nix via official installer with daemon mode
- Skips if already present

**Usage**:
```bash
just install-nix
```

---

### `just install-home-manager`

**Description**: Install home-manager

**What it does**:
- Checks if home-manager is installed
- Adds home-manager channel
- Installs home-manager via nix-shell
- Skips if already present

**Usage**:
```bash
just install-home-manager
```

---

### `just install-uidmap`

**Description**: Install uidmap for containers (Linux only)

**What it does**:
- Checks if newuidmap and newgidmap exist
- Installs uidmap package via apt (requires sudo)
- Skips on non-Linux systems

**Usage**:
```bash
just install-uidmap
```

**Requirements**: Linux system with apt package manager

---

### `just apply-zsh`

**Description**: Configure zsh as default shell

**What it does**:
- Adds Nix zsh to /etc/shells
- Changes default shell to zsh

**Usage**:
```bash
just apply-zsh
```

**Requirements**: zsh must be installed via home-manager first

---

## System-Specific Configurations

### `just setup-mac-power-schedule`

**Description**: Setup macOS power schedule (macOS only)

**What it does**:
- Prompts for confirmation (interactive)
- Clears existing power schedules
- Sets sleep time: 02:00:00 daily
- Sets wake time: 06:30:00 daily

**Usage**:
```bash
just setup-mac-power-schedule
```

**Platform**: macOS only (automatically skipped on other platforms)

**Configuration**:
Variables at top of justfile:
```bash
MAC_SLEEP_TIME := "02:00:00"
MAC_WAKE_TIME := "06:30:00"
MAC_SCHEDULE_DAYS := "MTWRFSU"
```

**Verification**:
```bash
sudo pmset -g sched
```

**To cancel**:
```bash
sudo pmset repeat cancel
```

---

### `just link-nix-conf`

**Description**: Link nix.conf to system configuration

**What it does**:
- Creates /etc/nix directory if needed
- Backs up existing nix.conf
- Symlinks dotfiles/nix/nix.conf to /etc/nix/nix.conf

**Usage**:
```bash
just link-nix-conf
```

**Requirements**: sudo access

---

## Maintenance and Cleanup

### `just smart-clean`

See [Primary Workflow](#just-smart-clean) section above.

---

### `just force-clean`

**Description**: Force garbage collection regardless of conditions (manual override)

**What it does**:
- Runs nix-collect-garbage with 14-day threshold
- Runs system-wide GC on NixOS (requires sudo)
- Records cleanup timestamp
- Ignores smart-clean conditions

**Usage**:
```bash
just force-clean
```

**When to use**:
- When store is very large and you want immediate cleanup
- When smart-clean keeps skipping
- Before major system updates
- When troubleshooting performance issues

**Warning**: May cause temporary performance impact during cleanup

---

### `just gc-status`

**Description**: Show garbage collection status and analysis

**What it does**:
- Shows current store size
- Shows days since last GC
- Shows disk usage percentage
- Displays GC configuration
- Shows available commands

**Usage**:
```bash
just gc-status
```

**Example output**:
```
=== GARBAGE COLLECTION STATUS ===
Current store size: 25G
Days since last GC: 0 days
Disk usage: 5%

=== CONFIGURATION ===
Size threshold: 10GB (legacy - using disk % now)
Min interval: 3 days
Max interval: 14 days
State file: .nix-gc-state

Commands:
  just smart-clean   # Run intelligent cleanup
  just force-clean   # Force cleanup regardless of conditions
```

---

### `just clear-all`

**Description**: Uninstall home-manager completely

**What it does**:
- Runs home-manager uninstall
- Removes all home-manager configurations

**Usage**:
```bash
just clear-all
```

**Warning**: This removes all home-manager configurations. Use with caution.

---

### `just remove-configs`

**Description**: Remove all dotfiles and configurations

**What it does**:
- Removes ~/.config/nvim
- Removes ~/.local/share/nvim
- Removes ~/.cache/nvim
- Removes SpaceVim configurations
- Removes .zshrc
- Uninstalls zsh via apt (requires sudo)

**Usage**:
```bash
just remove-configs
```

**Warning**: Destructive operation. Make sure to backup important configurations first.

---

### `just enable-shared-mount`

**Description**: Enable shared mount for rootless podman

**What it does**:
- Checks if root filesystem has shared propagation
- Runs `sudo mount --make-rshared /` if needed
- Skips if already configured

**Usage**:
```bash
just enable-shared-mount
```

**When to use**:
- When encountering podman permission errors
- Before using minikube with podman driver
- Part of container troubleshooting

---

### `just performance-test`

**Description**: Run comprehensive Nix performance analysis

**What it does**:
- Shows store metrics and disk usage
- Displays configuration status
- Shows binary cache configuration
- Displays garbage collection analysis
- Runs quick performance test
- Shows store optimization potential
- Provides GC recommendations

**Usage**:
```bash
just performance-test
```

**Example output sections**:
1. Store metrics (size, paths, disk usage)
2. Configuration status (auto-optimise, max-jobs, cores)
3. Binary cache status
4. Garbage collection analysis
5. Quick performance test
6. Store optimization potential
7. Smart GC recommendations

---

## Development Connections

### `just source-env`

**Description**: Load environment variables from scripts/env.sh

**What it does**:
- Sources scripts/env.sh
- Validates required environment variables
- Displays loaded variables (masked)

**Usage**:
```bash
just source-env
```

**Requirements**: scripts/env.sh must exist with proper credentials

**Environment variables loaded**:
- AQUANURI_BASTION_URL
- AQUANURI_BASTION_PW
- AQUANURI_BASTION_PORT
- AQUANURI_TARGET_URL
- AQUANURI_LOCAL_PORT
- HAMA_VPN_PW

📖 See [Development Connections Guide](../integrations/development-connections.md) for setup details.

---

### `just aquanuri-connect`

**Description**: Connect to Aquanuri development database via SSH tunnel

**What it does**:
- Sources environment variables
- Creates SSH tunnel to development database
- Handles password authentication automatically

**Usage**:
```bash
just source-env          # Load credentials first
just aquanuri-connect    # Connect to database
```

📖 See [Development Connections Guide](../integrations/development-connections.md) for complete setup.

---

### `just vpn-connect`

**Description**: Connect to VPN (default: lonelynight1026.ovpn)

**What it does**:
- Sources environment variables
- Connects to VPN using OpenVPN
- Handles password authentication automatically

**Usage**:
```bash
just source-env                    # Load credentials first
just vpn-connect                   # Use default config
just vpn-connect custom-config.ovpn  # Use custom config
```

📖 See [Development Connections Guide](../integrations/development-connections.md) for complete setup.

---

## Image Generation

### `just list-image-formats`

**Description**: Show available image formats with descriptions

**What it does**:
- Lists all supported image formats
- Shows descriptions and use cases
- Displays current system architecture

**Usage**:
```bash
just list-image-formats
```

---

### `just build-image`

**Description**: Build specific format for current architecture

**What it does**:
- Builds specified image format for your system
- Uses nix build internally
- Shows output location when complete

**Usage**:
```bash
just build-image iso
just build-image virtualbox
just build-image vmware
just build-image qcow
```

📖 See [Image Generation Guide](image-generation.md) for complete documentation.

---

### `just build-image-arch`

**Description**: Build specific format for specific architecture

**What it does**:
- Builds image for explicitly specified architecture
- Useful for cross-architecture builds

**Usage**:
```bash
just build-image-arch iso x86_64-linux
just build-image-arch qcow aarch64-linux
```

---

### `just build-all-images`

**Description**: Build all formats for current architecture

**What it does**:
- Builds all supported image formats
- Shows success/failure for each format
- Reports any failures at the end

**Usage**:
```bash
just build-all-images
```

**Warning**: Requires significant disk space (10GB+) and time

---

### `just show-images`

**Description**: Show built images and their sizes

**What it does**:
- Lists all result* directories
- Shows file sizes in human-readable format

**Usage**:
```bash
just show-images
```

---

## Manual Home-Manager Operations

For advanced users who want to manually control home-manager operations:

### Architecture-Aware Configurations

```bash
# WSL x64
home-manager switch --flake .#hm-wsl-x86_64-linux -b back

# ARM64 Linux
home-manager switch --flake .#hm-aarch64-linux -b back

# Intel macOS
home-manager switch --flake .#hm-x86_64-darwin -b back

# Apple Silicon macOS
home-manager switch --flake .#hm-aarch64-darwin -b back

# NixOS (in addition to nixos-rebuild)
home-manager switch --flake .#hm-nixos-x86_64-linux -b back
```

### Dry Run (Test Without Applying)

```bash
home-manager switch --flake .#hm-x86_64-linux --dry-run
home-manager switch --flake .#hm-wsl-x86_64-linux --dry-run
home-manager switch --flake .#hm-aarch64-darwin --dry-run
```

### Build Only (No Activation)

```bash
home-manager build --flake .#hm-x86_64-linux
nix build .#homeConfigurations.hm-x86_64-linux.activationPackage
```

---

## Environment Variables Reference

These variables are automatically set by justfile and can be referenced:

| Variable | Description | Example |
|----------|-------------|---------|
| `USERNAME` | Current user | `limjihoon` |
| `HOSTNAME` | System hostname | `my-machine` |
| `OS_TYPE` | Operating system type | `nixos`, `darwin`, `wsl`, `unsupported` |
| `SYSTEM_ARCH` | System architecture | `x86_64-linux`, `aarch64-darwin` |
| `GC_SIZE_THRESHOLD_GB` | GC size threshold | `10` |
| `GC_MIN_INTERVAL_DAYS` | Minimum GC interval | `3` |
| `GC_MAX_INTERVAL_DAYS` | Maximum GC interval | `14` |
| `GC_STATE_FILE` | GC state tracking file | `.nix-gc-state` |

### Using Environment Variables

```bash
# Check detected values
echo "OS: $(just OS_TYPE), Arch: $(just SYSTEM_ARCH)"

# Use in custom commands
just install-pckgs $(just SYSTEM_ARCH)
```

---

## Command Combinations

### Complete Fresh Installation

```bash
just install-all
```

Equivalent to:
```bash
just install-nix
just link-nix-conf
just install-home-manager
just install-uidmap-conditional
just install-pckgs
just setup-mac-power-schedule  # macOS only
just smart-clean
```

### Development Session Setup

```bash
just source-env
just aquanuri-connect
# ... work in another terminal ...
just vpn-connect
```

### Performance Troubleshooting

```bash
just performance-test  # Analyze system
just gc-status         # Check GC status
just force-clean       # Force cleanup if needed
```

### Image Generation Workflow

```bash
just list-image-formats  # See available formats
just build-image iso     # Build ISO
just show-images         # Check result
```

---

## See Also

- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions
- [Development Workflow Guide](development-workflow.md) - Recommended workflows
- [SSD Optimization Guide](ssd-optimization.md) - Performance and longevity
- [Image Generation Guide](image-generation.md) - Complete image building reference
- [Development Connections Guide](../integrations/development-connections.md) - Environment setup
