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
   sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix
   ```
3. **Apply the configuration**:
   ```bash
   just install-all
   ```

> **Note**: `hardware-configuration.nix` is excluded from git (`.gitignore`) because it contains machine-specific settings like disk UUIDs, kernel modules, and CPU types that differ between hosts.

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

# Specific installations
just install-nix           # Install Nix package manager
just install-home-manager  # Install home-manager
just apply-zsh            # Configure zsh shell
```

> **Tip**: See `CLAUDE.md` for detailed development workflows and troubleshooting.



## ⚡ SSD Optimization Features

This configuration includes several optimizations to reduce SSD wear and extend drive lifespan:

### Automatic Optimizations
- **Binary Caches**: Uses Cachix and community caches to minimize local builds (80-90% reduction in SSD writes)
- **Tmpfs Mounts**: Build directories (`/tmp`, `/var/tmp`) use RAM instead of SSD storage
- **Smart Garbage Collection**: Weekly automatic cleanup instead of frequent manual runs
- **Journal Limiting**: SystemD logs are capped at 500MB with automatic rotation
- **Firmware Updates**: fwupd service enabled for SSD firmware optimization

### Manual Hardware Optimizations
For NixOS systems, add these mount options to your `hardware-configuration.nix`:

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

## 🐛 Troubleshooting

### Common Issues

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

### Getting Help

- Check `CLAUDE.md` for detailed development workflows
- Review individual module files in `modules/` for specific configurations
- File issues on the repository for bugs or feature requests


## 📚 Additional Resources

- **[CLAUDE.md](./CLAUDE.md)**: Detailed development workflows and architecture
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
