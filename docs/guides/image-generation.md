# Image Generation Guide

This guide explains how to create bootable ISOs, VM images, and container images from your NixOS configuration using nixos-generators.

## Table of Contents

- [Overview](#overview)
- [Supported Formats](#supported-formats)
- [Quick Start](#quick-start)
- [Advanced Usage](#advanced-usage)
- [Use Cases](#use-cases)
- [Troubleshooting](#troubleshooting)

---

## Overview

This flake includes nixos-generators integration for creating various system images. You can generate bootable ISOs, VM images, and container images from your NixOS configuration with automatic multi-architecture support.

### Key Features

- **Multi-architecture**: Automatic generation for x86_64-linux and aarch64-linux
- **Multiple formats**: ISO, VirtualBox, VMware, QEMU/KVM
- **Consistent configuration**: Images use your exact NixOS configuration
- **Binary caches**: Leverages existing caches to speed up builds

---

## Supported Formats

The following image formats are supported with automatic multi-architecture generation:

| Format | Description | Use Case | Architectures |
|--------|-------------|----------|---------------|
| `iso` | Bootable ISO image | Installation media, live boot | x86_64-linux, aarch64-linux |
| `virtualbox` | VirtualBox OVA | VirtualBox virtualization | x86_64-linux, aarch64-linux |
| `vmware` | VMware VMDK | VMware virtualization | x86_64-linux, aarch64-linux |
| `qcow` | QEMU qcow2 | KVM/libvirt, cloud deployments | x86_64-linux, aarch64-linux |

### Architecture Support

Images are automatically generated for Linux architectures:
- **x86_64-linux**: Intel/AMD 64-bit systems
- **aarch64-linux**: ARM64 systems

**Note**: macOS (Darwin) architectures are not supported for image generation as this is NixOS-specific functionality.

---

## Quick Start

### List Available Formats

```bash
just list-image-formats
```

This displays all available formats with descriptions:
```
Available image formats for x86_64-linux:

Format        Description
----------    -----------
iso           Bootable ISO image for installation/live boot
virtualbox    VirtualBox OVA image
vmware        VMware VMDK image
qcow          QEMU qcow image for KVM/libvirt

Usage: just build-image <format>

Note: For Docker containers, use official NixOS Docker images instead.
```

### Build Single Image

Build for your current architecture:
```bash
# Bootable ISO
just build-image iso

# VirtualBox image
just build-image virtualbox

# QEMU/KVM image
just build-image qcow

# VMware image
just build-image vmware
```

### Build for Specific Architecture

```bash
# Build ISO for x86_64
just build-image-arch iso x86_64-linux

# Build QEMU image for ARM64
just build-image-arch qcow aarch64-linux
```

### Build All Formats

Build all available formats for your current architecture:
```bash
just build-all-images
```

This will build:
- Bootable ISO
- VirtualBox OVA
- VMware VMDK
- QEMU qcow2

### Check Built Images

View built images and their sizes:
```bash
just show-images
```

Example output:
```
Built images in ./result*:

result-iso/nixos.iso      1.2G
result-virtualbox/*.ova   1.5G
result-qcow/*.qcow2       1.1G
```

---

## Advanced Usage

### Direct Nix Commands

You can also use nix build directly for more control:

```bash
# Current system architecture
nix build .#iso
nix build .#virtualbox
nix build .#vmware
nix build .#qcow

# Specific architecture
nix build .#packages.x86_64-linux.iso
nix build .#packages.aarch64-linux.qcow

# With verbose output
nix build .#iso --verbose

# Dry run to see what will be built
nix build .#iso --dry-run
```

### Check Available Outputs

View all available flake outputs:
```bash
nix flake show
```

### Validate Image Configuration

Check image configuration without building:
```bash
# Validate specific image
nix eval .#packages.x86_64-linux.iso.meta --json

# Check image metadata
nix build .#packages.x86_64-linux.iso --dry-run
```

---

## Use Cases

### Installation Media

Create bootable USB drives for NixOS installation:

```bash
# Build ISO
just build-image iso

# Burn to USB (Linux)
sudo dd if=result/iso/nixos.iso of=/dev/sdX bs=4M status=progress

# Burn to USB (macOS)
sudo dd if=result/iso/nixos.iso of=/dev/diskX bs=4m
```

**Note**: Replace `/dev/sdX` or `/dev/diskX` with your actual USB device. Use `lsblk` (Linux) or `diskutil list` (macOS) to identify the correct device.

### Virtual Machines

#### VirtualBox

```bash
# Build VirtualBox image
just build-image virtualbox

# Import in VirtualBox
# File → Import Appliance → Select result/virtualbox/*.ova
```

**Tips**:
- Allocate at least 2GB RAM
- Enable VT-x/AMD-V in BIOS
- Configure network as needed (NAT, Bridged, etc.)

#### VMware

```bash
# Build VMware image
just build-image vmware

# Import in VMware
# File → Open → Select result/vmware/*.vmdk
```

#### KVM/libvirt (QEMU)

```bash
# Build QEMU image
just build-image qcow

# Use with virt-manager
# Create new VM → Import existing disk image → Select result/qcow/*.qcow2

# Or use with qemu command directly
qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -hda result/qcow/*.qcow2 \
  -net nic -net user
```

### Cloud Deployment

QEMU images can be used for cloud platforms:

```bash
# Build qcow image
just build-image qcow

# Convert for other cloud formats if needed
qemu-img convert -f qcow2 -O vpc result/qcow/*.qcow2 azure-image.vhd  # Azure
qemu-img convert -f qcow2 -O vmdk result/qcow/*.qcow2 aws-image.vmdk  # AWS
```

### Testing and Development

Use images for:
- Testing configuration changes in isolated environments
- Demonstrating your setup to others
- Creating consistent development environments
- Backup and disaster recovery

---

## Troubleshooting

### Common Issues

#### "No such flake output attribute"

**Symptom**: Error when trying to build image

**Solution**: Ensure you're using a Linux architecture:
```bash
# Image generation only works on Linux architectures
just build-image-arch iso x86_64-linux
just build-image-arch qcow aarch64-linux

# Not supported (will error):
# just build-image-arch iso x86_64-darwin
```

#### Build Timeouts

**Symptom**: Build process times out or takes very long

**Solutions**:
```bash
# Increase timeout (default is 2 minutes)
nix build .#iso --timeout 3600  # 1 hour

# Use binary caches (already configured)
nix show-config | grep substituters

# Build with verbose output to track progress
nix build .#iso --verbose
```

**Note**: First build may take 20-30 minutes. Subsequent builds will be much faster due to caching.

#### Disk Space Issues

**Symptom**: "No space left on device" during build

**Requirements**:
- At least **10GB free** in `/nix/store`
- Additional **2-3GB** for each image format

**Solutions**:
```bash
# Check available space
df -h /nix/store

# Run garbage collection
just force-clean

# Check store size after cleanup
du -sh /nix/store

# Remove old image results
rm -rf result*
```

#### Memory Usage Issues

**Symptom**: System becomes unresponsive during build

**Requirements**:
- Minimum **8GB RAM** recommended
- **16GB RAM** for building multiple formats simultaneously

**Solutions**:
```bash
# Build images one at a time
just build-image iso
just build-image virtualbox
just build-image qcow

# Instead of:
# just build-all-images  # May require more memory
```

#### Image Won't Boot

**Symptom**: Built image doesn't boot in VM or physical hardware

**Solutions**:

1. **Verify image integrity**:
   ```bash
   # Check image file exists and has reasonable size
   ls -lh result*/
   ```

2. **Check VM configuration**:
   - Enable VT-x/AMD-V in BIOS
   - Allocate sufficient RAM (minimum 2GB)
   - Use correct boot mode (UEFI vs Legacy)

3. **Rebuild with clean state**:
   ```bash
   # Remove old results
   rm -rf result*

   # Clean nix store
   just force-clean

   # Rebuild image
   just build-image iso
   ```

### Debugging Commands

```bash
# Check available outputs
nix flake show

# Validate specific image configuration
nix build .#packages.x86_64-linux.iso --dry-run

# Build with verbose output
nix build .#iso --verbose

# Check image metadata
nix eval .#packages.x86_64-linux.iso.meta --json

# Verify binary cache usage
nix build .#iso --print-build-logs
```

### Performance Tips

1. **Use binary caches** (already configured):
   ```bash
   # Verify cache configuration
   nix show-config | grep substituters
   ```

2. **Build images one at a time** if memory is limited:
   ```bash
   just build-image iso
   # Wait for completion, then:
   just build-image virtualbox
   ```

3. **Clean old results** before building new images:
   ```bash
   rm result*
   ```

4. **Monitor disk usage**:
   ```bash
   just show-images  # Check image sizes
   du -sh /nix/store  # Check store size
   ```

5. **Optimize store** before large builds:
   ```bash
   just force-clean
   nix store optimise
   ```

---

## Note on Docker Containers

For Docker containers, **use official NixOS Docker images** instead of generating custom images from this configuration.

This setup is optimized for:
- VM and installation media generation
- Bootable ISOs
- Hypervisor-specific formats

For containers:
```bash
# Use official NixOS Docker images
docker pull nixos/nix

# Or use nixpkgs dockerTools
# See: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-dockerTools
```

---

## Additional Resources

- [NixOS Manual - Building Images](https://nixos.org/manual/nixos/stable/#sec-building-image)
- [nixos-generators Documentation](https://github.com/nix-community/nixos-generators)
- [Justfile Commands Reference](commands-reference.md)
- [Troubleshooting Guide](troubleshooting.md)

For questions or issues:
- Run `just performance-test` for system analysis
- Check [Troubleshooting Guide](troubleshooting.md)
- File issues on the repository
