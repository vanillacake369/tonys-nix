# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal Nix configuration repository using flakes and home-manager for managing multi-platform development environments (NixOS, WSL, macOS). The configuration provides a comprehensive development setup with tools for Go, Java, Kubernetes, Docker, and modern CLI utilities.

## Essential Commands

### Primary workflow (recommended)
```bash
just install-all           # Complete installation pipeline (nix, home-manager, packages)
just install-pckgs         # Install packages using home-manager (auto-detects system)
just smart-clean           # Intelligent SSD-optimized cleanup (skips when not needed)
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
just smart-clean                   # Intelligent SSD-optimized garbage collection
just force-clean                   # Force cleanup regardless of conditions (manual override)
just clean                         # Legacy cleanup (same as force-clean)
just gc-status                     # Show garbage collection status and analysis
just clear-all                     # Uninstall home-manager completely
just remove-configs                # Remove all dotfiles and configs
just enable-shared-mount           # Enable shared mount for rootless podman
just performance-test              # Run comprehensive Nix performance analysis
```

### Development connections
```bash
just source-env                    # Load environment variables from scripts/env.sh
just aquanuri-connect              # Connect to Aquanuri development database via SSH tunnel
just vpn-connect [config]          # Connect to VPN (default: lonelynight1026.ovpn)
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
just gc-status                                                # Check garbage collection status
just force-clean                                              # Manual garbage collection override
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
- **karabiner/**: macOS keyboard remapping with productivity shortcuts

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
4. **Smart cleanup**: Run `just smart-clean` for intelligent SSD-optimized cleanup (or use `just install-all` which includes smart cleanup)

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
- **Environment variables not loaded**: Run `just source-env` to load development credentials from `scripts/env.sh`
- **SSH/VPN connection issues**: Check environment variables are set with `just source-env`, then use `just aquanuri-connect` or `just vpn-connect`

### SSD Optimization for New Machines
When setting up on a new NixOS machine, optimize the hardware configuration for SSD longevity:

#### Mount Options Explained:
- **`noatime`**: Prevents file access time updates, reducing write operations
- **`discard=async`**: Enables asynchronous TRIM for better SSD wear leveling
- **Important**: These options must be added per-machine in `/etc/nixos/hardware-configuration.nix` since it's gitignored and machine-specific

#### Automatic Performance & SSD Optimizations (Already Configured):
- **Store auto-optimization**: Automatic deduplication reduces store size and improves I/O performance
- **Optimized build settings**: Uses all available CPU cores with `max-jobs=auto` and `cores=0`
- **Smart Garbage Collection**: Intelligent cleanup that runs only when needed (size > 10GB or > 14 days), reducing SSD wear by 80-90%
- **Binary caches**: Reduces local builds by 80-90% (cache.nixos.org, nix-community, devenv)
- **Journal limits**: SystemD logs capped at 500MB with monthly rotation
- **fwupd**: Firmware update capability for SSD optimization

#### Smart Garbage Collection System
This configuration includes an intelligent garbage collection system that dramatically reduces SSD wear:

**How it works:**
- **Size threshold**: Only runs GC when `/nix/store` exceeds 10GB
- **Time intervals**: Minimum 3 days between runs, forced after 14 days
- **Automatic decision**: Evaluates store size and last cleanup time before running
- **SSD protection**: Eliminates 80-90% of unnecessary cleanup operations

**Commands:**
```bash
just smart-clean    # Intelligent cleanup (used in install-all pipeline)
just force-clean    # Manual override to force cleanup
just gc-status      # Show detailed analysis and recommendations
just clean          # Legacy command (same as force-clean)
```

**Status monitoring:**
```bash
# Check current garbage collection status
just gc-status

# Example output:
# === GARBAGE COLLECTION STATUS ===
# Current store size: 8.2GB
# Days since last GC: 2 days
# Status: → GC would be skipped (store within limits)
# Advice: Store is clean, no action needed
```

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

## Development Environment Setup

### Environment Variables and Connections

This repository includes scripts for connecting to development resources. These require environment variables stored in `scripts/env.sh`.

#### Setting Up Development Connections

**Important**: The `scripts/env.sh` file contains sensitive credentials and is gitignored for security.

1. **Create environment file** (one-time setup):
```bash
# Create scripts/env.sh with your credentials
cat > scripts/env.sh << 'EOF'
#!/bin/bash
# Environment variables for development
# Usage: source scripts/env.sh

# Aquanuri DB connection
export AQUANURI_BASTION_URL="your-bastion-host"
export AQUANURI_BASTION_PW="your-password"  
export AQUANURI_BASTION_PORT="3306"
export AQUANURI_TARGET_URL="your-target-host"
export AQUANURI_LOCAL_PORT="3307"

# VPN credentials
export HAMA_VPN_PW="your-vpn-password"
EOF
```

2. **Load environment variables**:
```bash
just source-env    # Loads and validates environment variables
```

3. **Connect to services**:
```bash
# SSH tunnel to development database
just aquanuri-connect

# VPN connection (requires OpenVPN config file)
just vpn-connect                        # Uses default: lonelynight1026.ovpn
just vpn-connect custom-config.ovpn     # Uses custom config file
```

#### Debugging Connection Issues

If automatic password insertion doesn't work:

1. **Verify environment loading**:
```bash
just source-env
echo $AQUANURI_BASTION_PW  # Should show your password
```

2. **Check debug output** - The aquanuri-dev.sh script includes debugging:
   - Shows first 3 characters of password + ***
   - Confirms when password prompt is detected
   - Reports when password is sent

3. **Common issues**:
   - Environment variables not loaded: Run `just source-env` first
   - SSH prompt pattern mismatch: Check expect pattern in script
   - Network connectivity: Verify target hosts are reachable

#### Security Notes

- `scripts/env.sh` is automatically gitignored to prevent credential exposure
- Passwords are scrubbed from environment after loading in expect scripts
- Debug output masks sensitive information (shows only first 3 characters)
- Use secure methods to distribute credentials across team/machines

### Workflow Integration

The development connection commands integrate with the standard workflow:

```bash
# Standard development session
just source-env          # Load credentials
just aquanuri-connect    # Connect to database
# ... work in another terminal ...
just vpn-connect         # Connect to VPN if needed
```

## macOS Keyboard Customization

### Karabiner-Elements Configuration

This repository includes a Karabiner-Elements configuration for macOS that provides Windows/GNOME-style keyboard shortcuts and quick app launching via Option+number combinations.

#### Key Mappings

**Windows/GNOME-style shortcuts** (work in all apps except terminals):
- `Ctrl+A` → `Cmd+A` (Select all)
- `Ctrl+C` → `Cmd+C` (Copy)
- `Ctrl+V` → `Cmd+V` (Paste)
- `Ctrl+X` → `Cmd+X` (Cut)
- `Ctrl+Z` → `Cmd+Z` (Undo)
- `Ctrl+S` → `Cmd+S` (Save)
- `Ctrl+W` → `Cmd+W` (Close tab/window)
- `Ctrl+T` → `Cmd+T` (New tab)

**Text navigation shortcuts**:
- `Ctrl+←/→` → `Option+←/→` (Word navigation)
- `Ctrl+Backspace` → `Option+Backspace` (Delete word)
- `Ctrl+Delete` → `Option+Delete` (Delete word forward)

**App launcher shortcuts**:
- `Cmd+1` → TickTick
- `Cmd+2` → Slack
- `Cmd+3` → Obsidian
- `Cmd+4` → Google Chrome
- `Cmd+5` → IntelliJ IDEA
- `Cmd+6` → GoLand
- `Cmd+Option+T` → WezTerm
- `Cmd+Option+D` → Docker Desktop
- `Cmd+Option+M` → YouTube Music
- `Cmd+Option+C` → Google Chrome
- `Cmd+Option+I` → IntelliJ IDEA
- `Cmd+Option+G` → GoLand

**Word navigation shortcuts**:
- `Ctrl+←/→` → `Option+←/→` (Word navigation in text)

**Other mappings**:
- Right Command → F18 (for custom shortcuts)

#### Configuration Location

The Karabiner configuration is located at `dotfiles/karabiner/karabiner.json`. When home-manager is applied, this file is symlinked to `~/.config/karabiner/karabiner.json`.

#### Terminal Exclusions

The Windows/GNOME-style shortcuts are automatically disabled in terminal applications to preserve their native behavior:
- Terminal.app
- iTerm2
- WezTerm
- Alacritty
- Kitty
- Emacs

This ensures that terminal applications maintain their expected keyboard shortcuts (e.g., `Ctrl+C` for interrupt).

## Claude Code Integration

### Available Slash Commands

This repository includes optimized Claude Code slash commands for development workflows. These commands provide structured, project-aware assistance:

#### `/solve` - Universal Problem Solver
Analyze and provide optimal solutions for any issue, bug, or requirement.

**Usage Examples:**
```bash
/solve "Getting permission denied when running just install-pckgs"
/solve "Need to add support for a new architecture in the flake"
/solve "Nix build is consuming too much disk space"
```

**Output Structure:**
- Problem analysis with root cause identification
- 3-5 solution options with trade-offs
- Recommended solution considering project patterns
- Detailed implementation plan with validation strategy

#### `/enhance` - Code and System Improvements
Improve existing code or systems with optimized solutions and safe migration strategies.

**Usage Examples:**
```bash
/enhance "The justfile install-pckgs command is becoming complex with platform detection"
/enhance "Home-manager module organization could be more maintainable"
/enhance "Performance optimization for Nix store operations"
```

**Output Structure:**
- Current state assessment with improvement opportunities
- Enhancement options with impact/effort analysis
- Recommended approach with project guidelines compliance
- Phased implementation strategy with rollback plan

#### `/scaffold` - Skeleton Code Generation (KISS)
Generate working skeleton code from requirements following the KISS (Keep It Simple, Stupid) principle.

**Usage Examples:**
```bash
/scaffold "Need a backup system for Nix configurations that can restore previous states"
/scaffold "Create a new module for development database connections"
/scaffold "Design a testing framework for Nix flake configurations"
```

**Output Structure:**
- Brief description of what we're building
- Minimal file structure
- Working code that can run immediately
- Simple instructions to get started
- 2-3 next steps to enhance further

**Note**: This command follows KISS principles - it creates the simplest working implementation without complex architectural analysis or multiple options. Start simple, optimize later.

#### `/debug` - Systematic Debugging
Debug specific issues with systematic root cause analysis and prevention strategies.

**Usage Examples:**
```bash
/debug "Home-manager fails with unclear dependency errors only on ARM64 Linux"
/debug "Podman containers won't start after system update"
/debug "SSH tunnel connection drops unexpectedly during development work"
```

**Output Structure:**
- Issue reproduction steps and investigation process
- Systematic hypothesis testing with evidence
- Multiple fix strategies (quick vs proper solutions)
- Prevention measures and monitoring recommendations

#### `/commit` - Smart Git Commit
Generate appropriate commit messages and handle git operations intelligently.

#### `/documentify` - Documentation Generation
Generate comprehensive documentation from code and configuration files.

#### `/forget-all` - Context Reset
Clear conversation context while preserving important project information.

### Command Design Philosophy

#### Project-Aware Solutions
All commands reference this `CLAUDE.md` file to provide solutions that:
- Follow existing code patterns and conventions
- Respect the multi-platform architecture
- Consider performance implications (SSD optimization, binary caches)
- Maintain compatibility with the current tooling ecosystem

#### Structured Decision Making
Every command follows a consistent pattern:
1. **Analysis**: Understand the problem/requirement in project context
2. **Options**: Present multiple approaches with clear trade-offs
3. **Recommendation**: Choose optimal solution with detailed justification
4. **Implementation**: Provide actionable steps with validation strategies

#### Quality Assurance
- Solutions include testing and validation approaches
- Risk assessment for each recommended approach
- Rollback procedures for system changes
- Performance impact considerations

### Integration with Development Workflow

These commands integrate seamlessly with the standard development process:

```bash
# Example workflow using Claude commands
/solve "Add support for new development tool in language.nix"     # Get implementation plan
# Apply the recommended solution
just install-pckgs                                                 # Test the changes
/debug "New tool causing build failures"                          # If issues arise
# Fix any problems identified
/enhance "Optimize the new tool integration for better performance" # Improve implementation
```

### Best Practices for Command Usage

1. **Be Specific**: Provide detailed context about your issue or requirement
2. **Include Error Messages**: When debugging, include exact error text and conditions
3. **Mention Constraints**: Specify any limitations (time, compatibility, resources)
4. **Reference Context**: Mention relevant files, modules, or system components
5. **Follow Up**: Use commands in sequence for complex problems (solve → debug → enhance)

### Command Files Location

The slash commands are stored in `dotfiles/claude/commands/` and automatically available when using Claude Code in this repository:
- `solve.md` - Universal problem solving
- `enhance.md` - Code and system improvements  
- `scaffold.md` - Architecture and skeleton generation
- `debug.md` - Systematic debugging and troubleshooting
- `commit.md` - Smart git commit operations
- `documentify.md` - Documentation generation
- `forget-all.md` - Context reset functionality