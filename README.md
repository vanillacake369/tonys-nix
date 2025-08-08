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
just install-all    # Complete setup pipeline
just install-pckgs  # Install/update packages
just clean         # Clean old generations

# Development connections (requires scripts/env.sh)
just source-env            # Load development environment variables
just aquanuri-connect      # Connect to Aquanuri database via SSH tunnel  
just vpn-connect [config]  # Connect to VPN (default: lonelynight1026.ovpn)

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
- **Optimized Build Settings**: Uses all CPU cores with `max-jobs=auto` for faster parallel builds
- **Binary Caches**: Uses Cachix and community caches to minimize local builds (80-90% reduction in SSD writes)
- **Smart Garbage Collection**: Daily automatic cleanup with 7-day retention for optimal performance
- **Journal Limiting**: SystemD logs are capped at 500MB with automatic rotation
- **Firmware Updates**: fwupd service enabled for SSD firmware optimization

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

Create bootable ISOs and VM images from your NixOS configuration using nixos-generators.

### Quick Start

```bash
# List available formats
just list-image-formats

# Build bootable ISO
just build-image iso

# Build VirtualBox image
just build-image virtualbox

# Build all formats
just build-all-images

# Check built images
just show-images
```

### Supported Formats

| Format | Description | Architecture Support |
|--------|-------------|---------------------|
| `iso` | Bootable installation ISO | x86_64-linux, aarch64-linux |
| `virtualbox` | VirtualBox OVA image | x86_64-linux, aarch64-linux |
| `vmware` | VMware VMDK image | x86_64-linux, aarch64-linux |
| `qcow` | QEMU/KVM qcow image | x86_64-linux, aarch64-linux |

### Use Cases

- **Installation Media**: Create bootable USB drives for NixOS installation
- **Virtual Machines**: Deploy consistent environments in VirtualBox, VMware, or KVM
- **Cloud Deployment**: Use qcow images for cloud platforms

> **Note**: For Docker containers, use official NixOS Docker images. This configuration is optimized for VM and installation media generation.

### Advanced Usage

```bash
# Build for specific architecture
just build-image-arch iso x86_64-linux
just build-image-arch qcow aarch64-linux

# Direct nix commands
nix build .#iso                           # Current architecture
nix build .#packages.x86_64-linux.iso     # Specific architecture
```

> **Note**: Image generation requires significant disk space (10GB+) and build time. Use binary caches to speed up the process.

## 🐛 Troubleshooting

### Common Issues

#### NixOS Configuration Issues

**Hardware Configuration Missing**
- **Symptom**: "path does not exist" or "fileSystems option does not specify root" errors
- **Solution**: Generate hardware config in the correct location:
  ```bash
  sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
  ```

**services.journald.settings Error**
- **Symptom**: "The option 'services.journald.settings' does not exist"
- **Solution**: Already fixed in current configuration (uses `extraConfig` instead)

**Slow Nix Builds/Installations**
- **Symptoms**: Nix installs taking longer than expected, large store sizes
- **Solutions**:
  ```bash
  # Run comprehensive performance analysis
  just performance-test
  
  # Check current store size
  du -sh /nix/store
  
  # Run manual store optimization
  nix store optimise
  
  # Check if auto-optimization is enabled
  nix show-config | grep auto-optimise
  ```

#### Minikube + Podman Issues

If you encounter container creation failures:

**Symptoms**: Container creation failures with permission denied errors

```
Failed to create /init.scope control group: Permission denied
Failed to allocate manager object: Permission denied
container exited unexpectedly
```

**Solutions**:

1. **Install Required Dependencies**
   
   ```bash
   # These packages are included in the infra.nix module
   # but ensure they're properly installed:
   # - cni plugins
   # - dbus (must be running via systemd)
   # - qemu, virtiofsd (for podman machine)
   # - crun, runc (container runtimes)
   ```

2. **Enable cgroup v2**
   
   ```bash
   # Check current cgroup version
   grep cgroup /proc/filesystems
   ```
   
   For WSL2, add to `.wslconfig`:
   ```ini
   [wsl2]
   kernelCommandLine = cgroup_no_v1=all
   ```

3. **Configure Shared Mount**
   
   ```bash
   just enable-shared-mount  # Automated via justfile
   # Or manually: sudo mount --make-rshared /
   ```

4. **Debug with Logs**
   
   ```bash
   # Generate detailed logs for troubleshooting
   minikube logs --file=logs.txt
   
   # Check podman status
   podman system info
   systemctl --user status podman
   ```

### Other Common Issues

- **Build failures**: Run `nix flake check` to validate syntax
- **Package conflicts**: Run `just clean` to remove old generations
- **Shell not updating**: Restart terminal or run `exec zsh`
- **Permission issues**: Ensure user is in required groups (docker, wheel)
- **Performance issues**: Check store optimization status and consider manual `nix store optimise`

#### Development Environment Connections

This repository includes scripts for development environment connections that require credentials:

**Environment Variables Missing**:
- **Symptom**: "Required environment variable not set" errors when running connection scripts
- **Solution**: Create and load environment variables:
  ```bash
  # Create scripts/env.sh with your credentials (gitignored)
  cat > scripts/env.sh << 'EOF'
  #!/bin/bash
  # Environment variables for development connections
  
  # Aquanuri database connection (SSH tunnel)
  export AQUANURI_BASTION_URL="your-bastion-host-ip"       # e.g. "10.0.13.122"
  export AQUANURI_BASTION_PW="your-ssh-password"           # SSH password
  export AQUANURI_BASTION_PORT="3306"                      # Remote MySQL port
  export AQUANURI_TARGET_URL="your-target-server-ip"       # e.g. "146.56.44.51"
  export AQUANURI_LOCAL_PORT="3307"                        # Local port for tunnel
  
  # VPN connection
  export HAMA_VPN_PW="your-vpn-password"                   # OpenVPN private key password
  EOF
  
  # Then load and use them:
  just source-env        # Load environment variables
  just aquanuri-connect  # SSH tunnel to database
  just vpn-connect       # VPN connection
  ```

**SSH/VPN Connection Issues**:
- **Symptom**: Password prompts not being handled automatically
- **Solutions**:
  - Ensure environment variables are loaded: `just source-env`
  - Check debug output in the connection scripts
  - Verify network connectivity to target hosts

#### Running Dynamically Linked Executables

**nix-ld Support**: This configuration includes nix-ld, which allows running non-Nix dynamically linked executables. If you encounter "No such file or directory" errors when running downloaded binaries:

- The system is already configured with essential libraries for most CLI tools
- For specific missing libraries, check error messages and add them to `programs.nix-ld.libraries` in configuration.nix
- Common use case: Running Python tools installed outside Nix (e.g., via pip in virtual environments)

### Getting Help

- Run `just performance-test` for comprehensive system analysis
- Check `CLAUDE.md` for detailed development workflows
- Review individual module files in `modules/` for specific configurations
- File issues on the repository for bugs or feature requests


## 🤖 Claude Code Integration

This repository includes optimized **Claude Code slash commands** for development workflows:

- **`/solve`** - Universal problem solver for issues, bugs, and requirements
- **`/enhance`** - Code and system improvements with migration strategies  
- **`/scaffold`** - Generate skeleton code and architecture from concepts
- **`/debug`** - Systematic debugging with root cause analysis

### Usage Examples

```bash
# Problem solving
/solve "Getting permission denied when running just install-pckgs"

# Code improvements
/enhance "The justfile install-pckgs command is becoming too complex"

# Implementation from ideas
/scaffold "Need a backup system for Nix configurations"

# Systematic debugging
/debug "Home-manager fails with dependency errors on ARM64 Linux"
```

These commands provide **project-aware solutions** that follow the repository's patterns, consider multi-platform support, and include detailed implementation plans with validation strategies.

> **Note**: Commands are stored in `dotfiles/claude/commands/` and automatically available in Claude Code. See [CLAUDE.md](./CLAUDE.md#claude-code-integration) for detailed usage and best practices.

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
