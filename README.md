# Multi-Platform Nix Configuration

A comprehensive personal Nix configuration using flakes and home-manager for multi-platform development environments.
Supports NixOS, WSL, macOS, and standard Linux distributions with automatic environment detection.

## ✨ Features

- **Multi-platform support**: NixOS, WSL, macOS (Intel & Apple Silicon), Linux
- **Automated setup**: One-command installation with environment detection
- **Development tools**: Go, Java, Kubernetes, Podman with compose support, modern CLI utilities
- **Desktop environment**: GNOME with Wayland optimizations (NixOS)
- **Shell configuration**: Zsh with oh-my-zsh and powerlevel10k
- **Editor setup**: Neovim with LazyVim configuration
- **Container support**: Rootless Podman with Docker compatibility and podman-compose
- **Image generation**: Create ISOs, VM images (VirtualBox, VMware, qcow2), and container images
- **Dynamic binary support**: nix-ld enabled for running non-Nix executables seamlessly
- **macOS productivity**: Karabiner-Elements config for Windows/GNOME shortcuts and app launching

## 📦 Included Packages

Packages are automatically managed through home-manager modules. Key categories include:

- **Development**: Go, Java (Zulu), Node.js, Python
- **DevOps**: kubectl, helm, k9s, minikube, podman-compose, AWS CLI
- **Editors**: Neovim (LazyVim), VS Code, JetBrains IDEs
- **Shell**: Zsh, oh-my-zsh, powerlevel10k, modern CLI tools (bat, fzf, ripgrep)
- **Applications**: Firefox, Chrome, Slack, Obsidian, LibreOffice

> **Note**: Package versions are automatically managed. Run `home-manager packages` to see current versions.

## 🚀 Quick Start

### Prerequisites

- Git (for cloning the repository)
- Internet connection (for downloading Nix and packages)

### One-Command Setup

The easiest way to get started:

```bash
git clone https://github.com/vanillacake369/my-nixos.git
cd my-nixos
./justfile install-all  # or just 'just' if you have just installed
```

This will automatically:
1. Install Nix package manager
2. Install home-manager 
3. Detect your system architecture
4. Install all packages and configurations
5. Set up your development environment

### Manual Installation

If you prefer step-by-step installation:

#### 1. Install Nix

```bash
# Multi-user installation (recommended)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Or single-user installation
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

#### 2. Install home-manager

```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```

#### 3. Install packages

```bash
# Install just command runner (optional but recommended)
nix-env -iA nixpkgs.just

# Apply configuration
just install-pckgs  # Auto-detects your system
```


## 🔧 Configuration

### Customizing for Your System

The configuration automatically detects your username and system architecture. However, you may want to customize:

1. **User Configuration**: Edit `limjihoon-user.nix` or create your own user file
2. **Module Selection**: Modify `home.nix` to enable/disable specific modules
3. **Package Selection**: Edit individual module files in `modules/` directory

### Multi-Host Deployment

This configuration is designed to work across multiple machines. When setting up on a new NixOS host:

#### For NixOS Systems

1. **Clone the repository** on your new machine
2. **Generate hardware configuration** for the new machine:
   ```bash
   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
   ```
3. **Apply the configuration**:
   ```bash
   just install-all
   ```

> **Note**: `hardware-configuration.nix` is excluded from git and stored in `/etc/nixos/` because it contains machine-specific settings like disk UUIDs, kernel modules, and CPU types that differ between hosts. The flake uses `--impure` flag to access this system-level configuration.

#### For Non-NixOS Systems (WSL, macOS, Linux)

The configuration works seamlessly across different hosts since home-manager doesn't require hardware-specific settings:

```bash
git clone <your-repo>
cd my-nixos
just install-all
```

### Supported Configurations

The flake automatically selects the appropriate configuration:

- `hm-x86_64-linux`: Standard Linux (64-bit)
- `hm-aarch64-linux`: ARM64 Linux
- `hm-wsl-x86_64-linux`: Windows Subsystem for Linux  
- `hm-x86_64-darwin`: Intel macOS
- `hm-aarch64-darwin`: Apple Silicon macOS

### Available Commands

```bash
# Primary workflow
just install-all    # Complete setup pipeline with intelligent cleanup
just install-pckgs  # Install/update packages
just smart-clean    # Intelligent SSD-optimized cleanup (skips when not needed)

# Development connections (requires scripts/env.sh)
just source-env            # Load development environment variables
just aquanuri-connect      # Connect to Aquanuri database via SSH tunnel  
just vpn-connect [config]  # Connect to VPN (default: lonelynight1026.ovpn)

# Maintenance and cleanup
just smart-clean           # Intelligent SSD-optimized garbage collection
just force-clean           # Force cleanup regardless of conditions
just gc-status             # Show garbage collection status and analysis
just clean                 # Legacy cleanup command (same as force-clean)

# Performance and diagnostics
just performance-test      # Run comprehensive Nix performance analysis

# Image generation
just list-image-formats    # Show available image formats
just build-image <format>  # Build specific image format
just build-all-images      # Build all image formats
just show-images           # Show built images and sizes

# Specific installations
just install-nix           # Install Nix package manager
just install-home-manager  # Install home-manager
just apply-zsh            # Configure zsh shell
```

> **Tip**: See `CLAUDE.md` for detailed development workflows and troubleshooting.



## ⚡ SSD Optimization Features

This configuration includes several optimizations to reduce SSD wear and extend drive lifespan:

### Automatic Performance & SSD Optimizations
- **Store Auto-Optimization**: Automatic deduplication reduces store size and improves I/O performance
- **Optimized Build Settings**: Uses all available CPU cores with `max-jobs=auto` for faster parallel builds
- **Binary Caches**: Uses Cachix and community caches to minimize local builds (80-90% reduction in SSD writes)
- **Smart Garbage Collection**: Intelligent cleanup system that runs only when needed (size > 10GB or > 14 days), reducing SSD wear by 80-90%
- **Journal Limiting**: SystemD logs are capped at 500MB with automatic rotation
- **Firmware Updates**: fwupd service enabled for SSD firmware optimization

### Smart Garbage Collection System
The configuration includes an intelligent garbage collection system designed to protect SSD lifespan:

**Key Features:**
- **Conditional execution**: Only runs when `/nix/store` exceeds 10GB or hasn't run for 14+ days
- **SSD protection**: Eliminates 80-90% of unnecessary cleanup operations
- **User transparency**: Clear feedback about cleanup decisions and recommendations
- **Manual override**: Force cleanup when needed with `just force-clean`

**Usage:**
```bash
# Check garbage collection status
just gc-status

# Run intelligent cleanup (automatically used in install-all)
just smart-clean

# Force cleanup regardless of conditions
just force-clean
```

### Manual Hardware Optimizations
For NixOS systems, add these mount options to your `/etc/nixos/hardware-configuration.nix`:

```nix
fileSystems."/" = {
  device = "/dev/your-device";
  fsType = "ext4";
  options = [ "noatime" "discard=async" ];
};
```

- `noatime` - Prevents access time updates (reduces writes)
- `discard=async` - Enables TRIM for better SSD management

### SSD Health Monitoring
```bash
# Check SSD health and firmware
sudo fwupdmgr get-devices
sudo fwupdmgr refresh && sudo fwupdmgr get-updates

# Monitor SSD usage (if available)
sudo smartctl -a /dev/nvme0n1
```

## 🖼️ Image Generation

Create bootable ISOs and VM images from your NixOS configuration. Supports multiple formats with automatic multi-architecture generation.

**Quick Start**:
```bash
just build-image iso          # Bootable ISO
just build-image virtualbox   # VirtualBox OVA
just build-all-images         # All formats
```

**Supported Formats**: ISO, VirtualBox OVA, VMware VMDK, QEMU qcow2

📖 **[Full Image Generation Guide](docs/guides/image-generation.md)** - Detailed documentation including use cases, troubleshooting, and advanced usage.

## 🐛 Troubleshooting

### Quick Diagnostics

```bash
just performance-test  # Comprehensive system analysis
just gc-status         # Check garbage collection status
nix flake check        # Validate configuration
```

### Common Issues

**NixOS Configuration**
- Hardware config missing → `sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix`
- Slow builds → `just smart-clean` then `just performance-test`

**Containers (Podman/Minikube)**
- Permission denied → `just enable-shared-mount`
- cgroup errors → Enable cgroup v2 in WSL config

**Development Environment**
- Missing env vars → Create `scripts/env.sh` and run `just source-env`
- Connection issues → Verify credentials and network connectivity

📖 **[Full Troubleshooting Guide](docs/guides/troubleshooting.md)** - Comprehensive solutions for all common issues, including NixOS configuration, performance, containers, development environment, and build problems.


## 🖥️ macOS Keyboard Customization

Karabiner-Elements configuration for macOS providing Windows/GNOME-style shortcuts and quick app launching.

**Windows/GNOME Shortcuts** (all apps except terminals):
- `Ctrl+C/V/X/A/Z/S` → Copy, paste, cut, select all, undo, save
- `Ctrl+T/W` → New/close tab
- `Ctrl+←/→` → Word navigation

**Quick App Launching**:
- `Cmd+1-6` → TickTick, Slack, Obsidian, Chrome, IntelliJ, GoLand
- `Cmd+Option+T/D/M/C/I/G` → WezTerm, Docker, Music, Chrome, IntelliJ, GoLand

📖 **[Full macOS Keyboard Guide](docs/platform/macos/keyboard.md)** - Complete key mappings, customization, and troubleshooting.

## 🤖 Claude Code Integration

Optimized **Claude Code slash commands** for Nix development workflows with automatic configuration sync.

**Available Commands**:
- `/solve` - Universal problem solver
- `/enhance` - Code and system improvements
- `/scaffold` - Generate working skeleton code (KISS approach)
- `/debug` - Systematic debugging

**Example**:
```bash
/solve "Getting permission denied when running just install-pckgs"
/enhance "Optimize justfile GC system to reduce SSD wear"
```

**Features**:
- Project-aware solutions following repository patterns
- Automatic config sync across machines (permissions, MCP servers)
- Detailed implementation plans with validation strategies

📖 **[Full Claude Code Integration Guide](docs/integrations/claude-code/overview.md)** - Complete command reference, configuration management, and best practices.

## 📚 Additional Resources

- **[CLAUDE.md](./CLAUDE.md)**: Detailed development workflows, architecture, and Claude Code integration
- **[Nix Tutorial](https://velog.io/@vanillacake369/Nix-Tutorial)**: In-depth Nix guide (Korean)
- **[Justfile Reference](./justfile)**: All available automation commands
- **[Home Manager Manual](https://nix-community.github.io/home-manager/)**: Official documentation

## 👍 Contributing

Contributions are welcome! Feel free to:

- Open issues for bugs or feature requests
- Submit pull requests for improvements
- Share your own configurations or customizations

---

**Enjoy your Nix journey!** 🎉
