# Platform Notes

`just apply` selects the correct flake target automatically. The notes below cover platform-specific behavior, tools, and known requirements.

## macOS

**Detected when:** `uname -s` returns `Darwin`.
**Flake targets:** `hm-aarch64-darwin` (Apple Silicon), `hm-x86_64-darwin` (Intel).

### macOS-Specific Packages

The following packages are installed only on macOS (via `lib.optionals isDarwin` in `modules/packages/apps.hm.nix` and `modules/shell/infra.nix`):

| Package | Purpose |
|---|---|
| AeroSpace | Tiling window manager |
| Karabiner | Keyboard remapping (config generated from `modules/keymap/`) |
| WezTerm | GPU-accelerated terminal emulator |
| AlDente | Battery charge limiter |
| JankyBorders | Active window border highlight |
| AppCleaner | Application uninstaller |
| Hidden Bar | Menu bar icon management |
| awscli | AWS CLI (infra tools, macOS only by default) |
| nuclei | HTTP vulnerability scanner |
| ngrok | Localhost tunnel |

### Karabiner and AeroSpace

Both configurations are generated from `modules/keymap/binds.nix` at build time. After `just apply`, the generated files are written to:

- `~/.config/karabiner/karabiner.json`
- `~/.config/aerospace/aerospace.toml`

AeroSpace is reloaded automatically when `modules/keymap/binds.nix` has uncommitted changes in git. To force a reload:

```bash
aerospace reload-config
```

### Power Schedule

`just apply` calls `just setup-mac-power-schedule`, which configures a repeating sleep/wake schedule via `pmset`. The defaults are:

- Sleep: 02:00 daily
- Wake: 06:30 daily

To reconfigure or apply manually:

```bash
just setup-mac-power-schedule
```

To cancel the schedule:

```bash
sudo pmset repeat cancel
```

---

## NixOS

**Detected when:** `/etc/nixos` exists.
**Flake target:** `hm-nixos-x86_64-linux`.

### Hardware Configuration

`just apply` calls `apply-system` on NixOS, which checks for `/etc/nixos/hardware-configuration.nix`. If absent, it generates one automatically:

```bash
sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
```

### System Rebuild

NixOS requires a system-level rebuild in addition to home-manager:

```bash
sudo nixos-rebuild switch --flake .#tony --impure
```

The `--impure` flag is required because `hardware-configuration.nix` is read from the host filesystem at `/etc/nixos/`, which is outside the flake's pure evaluation context.

### Hyprland

Hyprland is enabled on NixOS via `modules/desktop/hyprland.nix`, imported conditionally with `lib.optionals isNixOs`.

---

## WSL

**Detected when:** `/proc/version` contains `Microsoft` or `WSL`.
**Flake target:** `hm-wsl-x86_64-linux`.

### uidmap

Rootless Podman and some container runtimes require `newuidmap` and `newgidmap`. `just bootstrap` installs `uidmap` via `apt` on Linux and WSL:

```bash
just install-uidmap
```

This step is skipped on NixOS and macOS.

### Shared Mount Propagation

For rootless Podman to work correctly, the root filesystem needs shared mount propagation:

```bash
just enable-shared-mount
```

This runs `sudo mount --make-rshared /`. The setting does not persist across WSL restarts; add it to a WSL startup script if needed.

### WSL-Specific Module

`modules/system/wsl.nix` is imported when `isLinux && !isNixOs`. It enables `targets.genericLinux` and configures the WSL environment.

---

## Plain Linux

**Detected when:** `uname -s` is `Linux` and neither NixOS nor WSL conditions match.
**Flake target:** `hm-x86_64-linux`.

### Fish Shell

`just apply` calls `apply-fish`, which:

1. Adds `~/.nix-profile/bin/fish` to `/etc/shells` if not already present.
2. Changes the login shell to fish via `chsh`.

This requires `sudo` for the `/etc/shells` write and may prompt for a password.

### uidmap

Same as WSL — `just bootstrap` runs `just install-uidmap` on plain Linux hosts.

### Linux GUI Packages

The following GUI packages are installed on Linux (excluding WSL), via `lib.optionals (isLinux && !isWsl)` in `modules/packages/apps.hm.nix`:

- Firefox
- Slack
- TickTick
- YTMDesktop
- LibreOffice (with English and Korean spell check)
