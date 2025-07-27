# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal Nix configuration repository using flakes and home-manager for managing Linux/WSL development environments. The configuration provides a comprehensive development setup with tools for Go, Java, Kubernetes, Docker, and more.

## Essential Commands

### Primary workflow (recommended)
```bash
just                    # Install everything (nix, home-manager, packages)
just install-pckgs      # Install packages using home-manager
just clean              # Clean up old Nix generations
```

### Individual installation steps
```bash
just install-nix                    # Install Nix package manager
just install-home-manager           # Install home-manager
just install-uidmap                 # Install uidmap for containers
just apply-zsh                      # Configure zsh as default shell
```

### System-specific configurations
```bash
just init-nixos                     # Apply NixOS system configuration
just install-pckgs wsl             # Install WSL-specific packages
just install-pckgs nixos           # Install NixOS-specific packages
```

### Maintenance
```bash
just clean                         # Garbage collect old Nix generations
just clear-all                     # Uninstall home-manager completely
just remove-configs                # Remove all dotfiles and configs
just enable-shared-mount           # Enable shared mount for rootless podman
```

### Manual home-manager operations
```bash
home-manager switch --flake .#hm-wsl -b back      # WSL configuration
home-manager switch --flake .#hm-nixos -b back    # NixOS configuration
nix-collect-garbage -d                            # Manual garbage collection
```

## Architecture

### Configuration Structure
- **flake.nix**: Main flake definition with inputs/outputs and system configurations
- **home.nix**: Core home-manager configuration importing all modules
- **configuration.nix**: NixOS system configuration (GNOME, services, security)
- **{username}-user.nix**: User-specific settings (username, home directory)

### Module Organization
- **modules/apps.nix**: Desktop applications (browsers, editors, productivity tools)
- **modules/infra.nix**: Infrastructure tools (Docker, Kubernetes, cloud tools)
- **modules/language.nix**: Programming language support (Go, Java, Node.js)
- **modules/nvim.nix**: Neovim configuration and plugins
- **modules/shell.nix**: Shell utilities (git, fzf, ripgrep, etc.)
- **modules/zsh.nix**: Zsh configuration with oh-my-zsh and powerlevel10k

### Dotfiles Management
Configuration files are symlinked from `dotfiles/` directory:
- `dotfiles/lazyvim/`: LazyVim Neovim configuration
- `dotfiles/zellij/`: Terminal multiplexer configuration
- `dotfiles/nix/` and `dotfiles/nixpkgs/`: Nix-specific configs

### Multi-Environment Support
The flake supports multiple configurations:
- **hm-wsl**: Home-manager configuration for WSL environments
- **hm-nixos**: Home-manager configuration for native NixOS
- **nixos**: Full NixOS system configuration

### Key Features
- Rootless Podman with Docker compatibility
- Korean input support (ibus-hangul)
- GNOME desktop environment with custom configurations
- SSH hardening with Google Authenticator 2FA
- Development tools for cloud-native and Kubernetes workflows
- Comprehensive shell environment with modern CLI tools

## Environment Detection

The justfile automatically detects the environment:
- WSL: Detected via `/proc/version` containing "Microsoft"
- NixOS: Detected by existence of `/etc/nixos`
- Darwin: Detected via `uname -s`
- Standard Linux: Default fallback

Use the appropriate home-manager configuration based on your environment.

## Troubleshooting

### Building/Testing
```bash
just                    # Test full installation pipeline
nix flake check         # Validate flake syntax and structure
home-manager switch --flake .#hm-wsl --dry-run    # Test WSL config without applying
home-manager switch --flake .#hm-nixos --dry-run  # Test NixOS config without applying
```

### Common Issues
- **Podman/Minikube fails**: Run `just enable-shared-mount` and ensure cgroup v2 is enabled
- **Korean input not working**: Verify `ibus-hangul` is installed and running
- **Flake lock conflicts**: Delete `flake.lock` and run `nix flake lock` to regenerate

### Development Workflow
1. Modify configuration in relevant module files
2. Test with dry-run: `home-manager switch --flake .#hm-{env} --dry-run`
3. Apply changes: `just install-pckgs` or `home-manager switch --flake .#hm-{env}`
4. Clean up: `just clean` to remove old generations