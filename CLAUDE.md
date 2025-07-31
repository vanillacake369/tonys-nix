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
- **hardware-configuration.nix**: NixOS hardware-specific settings
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
- Rootless Podman with Docker compatibility
- Korean input support (ibus-hangul) for desktop environments
- GNOME desktop environment with Wayland optimizations
- SSH hardening with Google Authenticator 2FA
- Comprehensive development environment for cloud-native workflows
- Modern shell environment with extensive CLI tooling

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

### Testing and Validation
```bash
just install-all                                           # Test complete installation pipeline
nix flake check                                           # Validate flake syntax and structure
home-manager switch --flake .#hm-x86_64-linux --dry-run  # Test Linux config without applying
home-manager switch --flake .#hm-wsl-x86_64-linux --dry-run # Test WSL config without applying
home-manager switch --flake .#hm-aarch64-darwin --dry-run # Test Apple Silicon config without applying
```

## Troubleshooting

### Common Issues and Solutions
- **Podman/Minikube container failures**: Run `just enable-shared-mount` and ensure cgroup v2 is enabled
- **Korean input not working**: Verify `ibus-hangul` is installed and running (`ibus-daemon -drx`)
- **Flake lock conflicts**: Delete `flake.lock` and regenerate with `nix flake lock`
- **Home-manager build failures**: Check for syntax errors with `nix flake check`
- **Architecture mismatch**: Verify correct platform detection with `just install-pckgs`

### Debugging Commands
```bash
# Check system detection
echo "OS: $(just OS_TYPE), Arch: $(just SYSTEM_ARCH)"

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