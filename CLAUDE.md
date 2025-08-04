# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal Nix configuration repository using flakes and home-manager for managing multi-platform development environments (NixOS, WSL, macOS). The configuration provides a comprehensive development setup with tools for Go, Java, Kubernetes, Docker, and modern CLI utilities.

## Essential Commands

### Primary workflow (recommended)
```bash
just install-all           # Complete installation pipeline (nix, home-manager, packages)
just install-pckgs         # Install packages using home-manager (auto-detects system)
just clean                 # Clean up old Nix generations
```

### Individual installation steps
```bash
just install-nix                    # Install Nix package manager
just install-home-manager           # Install home-manager
just install-uidmap                 # Install uidmap for containers (Linux only)
just apply-zsh                      # Configure zsh as default shell
```

### System-specific configurations
```bash
# Architecture-specific installations (auto-detected)
just install-pckgs x86_64-linux     # 64-bit Linux
just install-pckgs aarch64-linux    # ARM64 Linux  
just install-pckgs x86_64-darwin    # Intel macOS
just install-pckgs aarch64-darwin   # Apple Silicon macOS
```

### Maintenance and cleanup
```bash
just clean                         # Garbage collect old Nix generations
just clear-all                     # Uninstall home-manager completely
just remove-configs                # Remove all dotfiles and configs
just enable-shared-mount           # Enable shared mount for rootless podman
just performance-test              # Run comprehensive Nix performance analysis
```

### Image generation
```bash
just list-image-formats            # Show available image formats with descriptions
just build-image <format>          # Build specific format for current architecture
just build-image-arch <format> <arch>  # Build specific format for specific architecture
just build-all-images              # Build all formats for current architecture
just show-images                   # Show built images and their sizes
```

### Manual home-manager operations
```bash
# Architecture-aware configurations
home-manager switch --flake .#hm-wsl-x86_64-linux -b back     # WSL x64
home-manager switch --flake .#hm-aarch64-linux -b back        # ARM64 Linux
home-manager switch --flake .#hm-x86_64-darwin -b back        # Intel macOS
home-manager switch --flake .#hm-aarch64-darwin -b back       # Apple Silicon macOS
nix-collect-garbage -d                                        # Manual garbage collection
```

## Repository Structure

### Core Configuration Files
- **flake.nix**: Main flake definition with multi-platform support (NixOS, WSL, macOS)
- **home.nix**: Core home-manager configuration importing all modules
- **configuration.nix**: NixOS system configuration (GNOME, services, security)
- **hardware-configuration.nix**: (gitignored) NixOS hardware-specific settings (stored in /etc/nixos/)
- **justfile**: Build automation with environment detection
- **limjihoon-user.nix**: Primary user configuration
- **nixos-user.nix**: NixOS-specific user settings

### Module Organization (`modules/`)
- **apps.nix**: Desktop applications (browsers, editors, productivity tools)
- **infra.nix**: Infrastructure and DevOps tools (Docker, Kubernetes, cloud CLI)
- **language.nix**: Programming language support (Go, Java, Node.js, Python)
- **nvim.nix**: Neovim configuration and plugin management
- **shell.nix**: Shell utilities (git, fzf, ripgrep, modern CLI tools)
- **zsh.nix**: Zsh configuration with oh-my-zsh and powerlevel10k

### Dotfiles Management (`dotfiles/`)
Configuration files are symlinked from dotfiles directory:
- **lazyvim/**: Complete LazyVim Neovim configuration with language support
- **learn-nvim/**: Alternative/experimental Neovim setup
- **zellij/**: Terminal multiplexer configuration and layouts
- **nix/** and **nixpkgs/**: Nix-specific configuration files
- **autohotkey/**: Windows automation scripts (for WSL environments)
- **screen/**: Screen session configurations

### Library Functions (`lib/`)
- **builders.nix**: Custom Nix builders and utility functions

### Multi-Platform Support
The flake provides architecture-aware configurations:
- **hm-x86_64-linux**: Standard Linux (64-bit)
- **hm-aarch64-linux**: ARM64 Linux
- **hm-wsl-x86_64-linux**: Windows Subsystem for Linux
- **hm-x86_64-darwin**: Intel macOS
- **hm-aarch64-darwin**: Apple Silicon macOS
- **nixos**: Full NixOS system configuration for host systems

### Key Features
- Multi-platform support with automatic environment detection
- Rootless Podman with Docker compatibility and podman-compose support
- Korean input support (ibus-hangul) for desktop environments
- GNOME desktop environment with Wayland optimizations
- SSH hardening with Google Authenticator 2FA
- Comprehensive development environment for cloud-native workflows
- Modern shell environment with extensive CLI tooling
- nix-ld support for running dynamically linked executables

## Environment Detection

The justfile automatically detects your system and architecture:

### Operating System Detection
- **WSL**: Detected via `/proc/version` containing "Microsoft" 
- **NixOS**: Detected by existence of `/etc/nixos` directory
- **macOS**: Detected via `uname -s` returning "Darwin"
- **Standard Linux**: Default fallback for other Linux distributions

### Architecture Detection  
- **x86_64**: Intel/AMD 64-bit systems
- **aarch64**: ARM64 systems (Apple Silicon, ARM servers)
- Auto-selects appropriate flake configuration based on detected platform

## Development Workflow

### Standard Development Process
1. **Modify configurations**: Edit relevant files in `modules/` or core config files
2. **Test changes**: Use dry-run to validate without applying changes
3. **Apply changes**: Run `just install-pckgs` for automatic platform detection
4. **Clean up**: Run `just clean` to remove old generations and free disk space

### Multi-Host Deployment
When deploying to multiple NixOS machines:

#### Initial Setup on New NixOS Host
```bash
# 1. Clone repository
git clone <repository-url>
cd tonys-nix

# 2. Generate hardware configuration for this machine
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix

# 3. Apply configuration
just install-all
```

#### Updating Existing Hosts
```bash
# Pull latest changes
git pull

# Apply updates (hardware-configuration.nix in /etc/nixos/ remains unchanged)
just install-pckgs
```

> **Important**: `hardware-configuration.nix` is excluded from git and stored in `/etc/nixos/` because it contains machine-specific settings (disk UUIDs, kernel modules, CPU types) that differ between hosts. The flake uses `--impure` flag to access this system-level configuration.

### Testing and Validation
```bash
just install-all                                           # Test complete installation pipeline
just performance-test                                      # Analyze Nix performance and configuration
nix flake check                                           # Validate flake syntax and structure
home-manager switch --flake .#hm-x86_64-linux --dry-run  # Test Linux config without applying
home-manager switch --flake .#hm-wsl-x86_64-linux --dry-run # Test WSL config without applying
home-manager switch --flake .#hm-aarch64-darwin --dry-run # Test Apple Silicon config without applying
```

## Troubleshooting

### Common Issues and Solutions
- **Hardware configuration missing**: Generate with `sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix`
- **Boot/filesystem errors on new machine**: Ensure `/etc/nixos/hardware-configuration.nix` matches the current machine's hardware
- **Flake evaluation errors with hardware config**: The flake uses `--impure` flag to access `/etc/nixos/hardware-configuration.nix` outside the git tree
- **services.journald.settings error**: Use `services.journald.extraConfig` instead (fixed in current configuration)
- **Slow Nix builds/installs**: Check if `auto-optimise-store` is enabled and store size with `du -sh /nix/store`
- **Large Nix store size**: Run `nix store optimise` manually or ensure automatic optimization is enabled
- **Podman/Minikube container failures**: Run `just enable-shared-mount` and ensure cgroup v2 is enabled
- **Korean input not working**: Verify `ibus-hangul` is installed and running (`ibus-daemon -drx`)
- **Flake lock conflicts**: Delete `flake.lock` and regenerate with `nix flake lock`
- **Home-manager build failures**: Check for syntax errors with `nix flake check`
- **Architecture mismatch**: Verify correct platform detection with `just install-pckgs`
- **Dynamically linked executables failing**: nix-ld is enabled with essential libraries; add missing libraries to `programs.nix-ld.libraries` in configuration.nix

### SSD Optimization for New Machines
When setting up on a new NixOS machine, optimize the hardware configuration for SSD longevity:

#### Mount Options Explained:
- **`noatime`**: Prevents file access time updates, reducing write operations
- **`discard=async`**: Enables asynchronous TRIM for better SSD wear leveling
- **Important**: These options must be added per-machine in `/etc/nixos/hardware-configuration.nix` since it's gitignored and machine-specific

#### Automatic Performance & SSD Optimizations (Already Configured):
- **Store auto-optimization**: Automatic deduplication reduces store size and improves I/O performance
- **Optimized build settings**: Uses all 8 CPU cores with `max-jobs=auto` and `cores=0`
- **Daily GC with 7-day retention**: More frequent cleanup for better performance and smaller store size
- **Binary caches**: Reduces local builds by 80-90% (cache.nixos.org, nix-community, devenv)
- **Journal limits**: SystemD logs capped at 500MB with monthly rotation
- **fwupd**: Firmware update capability for SSD optimization

#### SSD Health Commands:
```bash
# Check SSD firmware and health
sudo fwupdmgr get-devices
sudo fwupdmgr refresh && sudo fwupdmgr get-updates

# Monitor SSD wear (if smartmontools available)
sudo smartctl -a /dev/nvme0n1

# Check Nix store size and optimization status
du -sh /nix/store
nix store optimise --dry-run  # Preview deduplication savings
```

### Debugging Commands
```bash
# Check system detection
echo "OS: $(just OS_TYPE), Arch: $(just SYSTEM_ARCH)"

# Performance and configuration analysis
just performance-test           # Comprehensive Nix performance analysis

# Hardware configuration validation
sudo nixos-generate-config --show-hardware-config  # Preview hardware config
ls -la /etc/nixos/hardware-configuration.nix       # Check if hardware config exists

# Validate flake configurations
nix flake show                  # List all available configurations
nix eval .#homeConfigurations   # Show home-manager configurations

# Test specific configurations
home-manager build --flake .#hm-x86_64-linux    # Build without applying
nix build .#homeConfigurations.hm-x86_64-linux.activationPackage  # Direct nix build
```

### Clean Installation (Reset)
```bash
just clear-all        # Remove home-manager completely
just remove-configs   # Remove all dotfiles and configurations
just install-all      # Fresh installation from scratch
```

## Image Generation

### Overview
This flake includes nixos-generators integration for creating various system images. You can generate bootable ISOs, VM images, and container images from your NixOS configuration.

### Available Formats
The following image formats are supported with automatic multi-architecture generation:

| Format | Description | Use Case |
|--------|-------------|----------|
| `iso` | Bootable ISO image | Installation media, live boot |
| `virtualbox` | VirtualBox OVA | VirtualBox virtualization |
| `vmware` | VMware VMDK | VMware virtualization |
| `qcow` | QEMU qcow | KVM/libvirt, cloud deployments |

### Architecture Support
Images are automatically generated for Linux architectures:
- **x86_64-linux**: Intel/AMD 64-bit systems
- **aarch64-linux**: ARM64 systems

### Basic Usage

#### List Available Formats
```bash
just list-image-formats
```

#### Build Single Image
```bash
# Build for current architecture
just build-image iso
just build-image virtualbox
just build-image qcow

# Build for specific architecture
just build-image-arch iso x86_64-linux
just build-image-arch qcow aarch64-linux
```

#### Build All Images
```bash
# Build all formats for current architecture
just build-all-images
```

#### Check Built Images
```bash
# Show built images and their sizes
just show-images
```

### Direct Nix Commands
You can also use nix build directly:

```bash
# Current system architecture
nix build .#iso
nix build .#virtualbox
nix build .#qcow

# Specific architecture
nix build .#packages.x86_64-linux.iso
nix build .#packages.aarch64-linux.qcow
```

### Use Cases

#### Installation Media
```bash
# Create bootable installation ISO
just build-image iso
# Burn to USB: dd if=result/iso/nixos.iso of=/dev/sdX bs=4M status=progress
```

#### Virtual Machines
```bash
# VirtualBox
just build-image virtualbox
# Import result/virtualbox/*.ova in VirtualBox

# VMware
just build-image vmware
# Import result/vmware/*.vmdk in VMware

# KVM/libvirt
just build-image qcow
# Use result/qcow/*.qcow with virt-manager
```

#### Note on Docker Containers
For Docker containers, use official NixOS Docker images instead of generating custom images from this configuration. Our setup is optimized for VM and installation media generation.

### Troubleshooting Image Generation

#### Common Issues
- **"No such flake output attribute"**: Ensure you're using a Linux architecture (x86_64-linux or aarch64-linux)
- **Build timeouts**: Large images may take time; increase timeout with `--timeout 3600`
- **Disk space**: Image generation requires significant disk space; ensure at least 10GB free
- **Memory usage**: Building multiple images simultaneously may require 8GB+ RAM

#### Debugging Commands
```bash
# Check available outputs
nix flake show

# Validate specific image configuration
nix build .#packages.x86_64-linux.iso --dry-run

# Build with verbose output
nix build .#iso --verbose

# Check image metadata
nix eval .#packages.x86_64-linux.iso.meta --json
```

#### Performance Tips
- Use binary caches to avoid rebuilding (already configured)
- Build images one at a time if memory is limited
- Clean old results: `rm result*` before building new images
- Use `just show-images` to monitor disk usage