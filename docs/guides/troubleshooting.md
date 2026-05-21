# Troubleshooting Guide

This guide covers common issues and their solutions when working with this Nix configuration.

## Table of Contents

- [NixOS Configuration Issues](#nixos-configuration-issues)
- [Performance & Store Issues](#performance--store-issues)
- [Container & Virtualization Issues](#container--virtualization-issues)
- [Development Environment Issues](#development-environment-issues)
- [Build & Installation Issues](#build--installation-issues)

---

## NixOS Configuration Issues

### Hardware Configuration Missing

**Symptom**: Errors like "path does not exist" or "fileSystems option does not specify root"

**Solution**: Generate hardware configuration in the correct location:
```bash
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
```

**Why this happens**: `hardware-configuration.nix` contains machine-specific settings (disk UUIDs, kernel modules, CPU types) and must be generated for each host.

### Boot/Filesystem Errors on New Machine

**Symptom**: Boot failures or filesystem mounting errors after cloning configuration

**Solution**: Ensure `/etc/nixos/hardware-configuration.nix` matches the current machine's hardware:
```bash
# Regenerate for current machine
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix

# Then reapply configuration
just apply
```

### Flake Evaluation Errors with Hardware Config

**Symptom**: "path '/etc/nixos/hardware-configuration.nix' does not exist" during flake evaluation

**Explanation**: The flake uses `--impure` flag to access `/etc/nixos/hardware-configuration.nix` outside the git tree. This is intentional because hardware config is machine-specific and gitignored.

**Solution**: Generate hardware config before running NixOS rebuild:
```bash
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
```

### services.journald.settings Error

**Symptom**: "The option 'services.journald.settings' does not exist"

**Solution**: Already fixed in current configuration (uses `services.journald.extraConfig` instead)

---

## Performance & Store Issues

### Slow Nix Builds/Installations

**Symptoms**: Installations taking longer than expected, rebuilds are slow

**Diagnostic Commands**:
```bash
# Run comprehensive performance analysis
just performance-test

# Check garbage collection status
just gc-info

# Check current store size
du -sh /nix/store

# Verify auto-optimization is enabled
nix show-config | grep auto-optimise
```

**Solutions**:

1. **Run intelligent cleanup** (recommended first):
   ```bash
   just gc
   ```

2. **Force cleanup if needed**:
   ```bash
   just gc-force
   ```

3. **Manual store optimization**:
   ```bash
   nix store optimise
   ```

4. **Check binary cache configuration**:
   ```bash
   nix show-config | grep substituters
   # Should show cache.nixos.org and community caches
   ```

### Large Nix Store Size

**Symptom**: `/nix/store` consuming too much disk space

**Solution**:
```bash
# Check current store size
du -sh /nix/store

# Check GC status and recommendations
just gc-info

# Run intelligent cleanup (skips if not needed)
just gc

# Force cleanup regardless of conditions
just gc-force

# Preview optimization savings
nix store optimise --dry-run

# Run optimization
nix store optimise
```

**Understanding Smart GC**:
- Only runs when store > 10GB or > 14 days since last cleanup
- Reduces SSD wear by 80-90%
- Use `just gc-info` to see current status and recommendations

### Flake Lock Conflicts

**Symptom**: Conflicts in `flake.lock` after pulling updates

**Solution**:
```bash
# Delete and regenerate flake lock
rm flake.lock
nix flake lock

# Or update all inputs
nix flake update
```

---

## Container & Virtualization Issues

### Minikube + Podman Container Creation Failures

**Symptoms**:
```
Failed to create /init.scope control group: Permission denied
Failed to allocate manager object: Permission denied
container exited unexpectedly
```

**Solutions**:

1. **Install Required Dependencies** (already included in infra.nix):
   - cni plugins
   - dbus (must be running via systemd)
   - qemu, virtiofsd (for podman machine)
   - crun, runc (container runtimes)

2. **Enable cgroup v2**:
   ```bash
   # Check current cgroup version
   grep cgroup /proc/filesystems

   # For WSL2, add to .wslconfig:
   # [wsl2]
   # kernelCommandLine = cgroup_no_v1=all
   ```

3. **Configure Shared Mount**:
   ```bash
   just enable-shared-mount
   # Or manually: sudo mount --make-rshared /
   ```

4. **Debug with Logs**:
   ```bash
   # Generate detailed logs
   minikube logs --file=logs.txt

   # Check podman status
   podman system info
   systemctl --user status podman
   ```

### Podman Rootless Issues

**Symptom**: Permission denied errors when running rootless containers

**Solution**:
```bash
# Ensure uidmap is installed (Linux only)
just install-uidmap

# Enable shared mount for rootless podman
just enable-shared-mount

# Verify cgroup configuration
grep cgroup /proc/filesystems
```

---

## Development Environment Issues

### Development Connection Scripts Not Available

Development connection scripts (SSH tunnels, VPN) are not included in this repository. Configure them separately per your organization's requirements.

### Korean Input Not Working

**Symptom**: Korean input method not functioning in desktop environment

**Solution**:
```bash
# Verify ibus-hangul is installed and running
ibus-daemon -drx

# Check ibus engines
ibus list-engine

# Restart ibus
killall ibus-daemon
ibus-daemon -drx
```

---

## Build & Installation Issues

### Home-Manager Build Failures

**Symptom**: Build errors when running `just apply`

**Solutions**:

1. **Validate flake syntax**:
   ```bash
   nix flake check
   ```

2. **Check for syntax errors in modules**:
   ```bash
   # Validate specific configuration
   nix build .#homeConfigurations.hm-x86_64-linux.activationPackage --dry-run
   ```

3. **Clear old generations and retry**:
   ```bash
   just gc-force
   just apply
   ```

### Architecture Mismatch

**Symptom**: Build errors mentioning unsupported architecture

**Solution**: Verify correct platform detection:
```bash
# Check detected architecture
echo "OS: $(just OS_TYPE), Arch: $(just SYSTEM_ARCH)"

# Manually specify architecture if needed
just apply x86_64-linux    # 64-bit Linux
just apply aarch64-linux   # ARM64 Linux
just apply x86_64-darwin   # Intel macOS
just apply aarch64-darwin  # Apple Silicon macOS
```

### Dynamically Linked Executables Failing

**Symptom**: "No such file or directory" errors when running downloaded binaries

**Explanation**: This configuration includes nix-ld to run non-Nix dynamically linked executables.

**Solution**: If specific libraries are missing, add them to `programs.nix-ld.libraries` in `configuration.nix`:
```nix
programs.nix-ld = {
  enable = true;
  libraries = with pkgs; [
    # Add missing libraries here
    stdenv.cc.cc
    zlib
    # ... other libraries
  ];
};
```

### Shell Not Updating

**Symptom**: Changes not reflected in shell after home-manager switch

**Solution**:
```bash
# Restart terminal or reload shell
exec fish

# Or source the new profile
source ~/.config/fish/config.fish
```

### Permission Issues

**Symptom**: Permission denied errors when running commands

**Solution**: Ensure user is in required groups:
```bash
# Check current groups
groups

# Add user to docker group (if using Docker compatibility)
sudo usermod -aG docker $USER

# Add user to wheel group (for sudo)
sudo usermod -aG wheel $USER

# Logout and login for group changes to take effect
```

---

## Advanced Diagnostics

### Comprehensive System Analysis

Run comprehensive performance and configuration analysis:
```bash
just performance-test
```

This shows:
- Store metrics and disk usage
- Configuration status
- Binary cache status
- Garbage collection recommendations
- Quick performance test results

### Hardware Configuration Validation

For NixOS systems:
```bash
# Preview hardware config
sudo nixos-generate-config --show-hardware-config

# Check if hardware config exists
ls -la /etc/nixos/hardware-configuration.nix

# Validate flake configurations
nix flake show
nix eval .#homeConfigurations
```

### Test Configurations Without Applying

```bash
# Test Linux config
home-manager build --flake .#hm-x86_64-linux

# Test WSL config
home-manager build --flake .#hm-wsl-x86_64-linux

# Test macOS config
home-manager build --flake .#hm-aarch64-darwin

# Direct nix build
nix build .#homeConfigurations.hm-x86_64-linux.activationPackage
```

---

## Clean Installation (Reset)

If all else fails, perform a clean installation:

```bash
# Remove home-manager completely
just uninstall-home-manager

# Remove all dotfiles and configurations
just purge-local-configs

# Fresh installation from scratch
just bootstrap
```

**Warning**: This will remove all home-manager configurations. Make sure to backup any important customizations first.

---

## Getting Additional Help

1. **Run performance analysis**: `just performance-test`
2. **Check GC status**: `just gc-info`
3. **Review module files**: Check individual files in `modules/` directory
4. **File issues**: Report bugs or feature requests on the repository
5. **Check CLAUDE.md**: Detailed development workflows and architecture

For platform-specific issues, see:
- [Platforms Guide](../getting-started/platforms.md)
