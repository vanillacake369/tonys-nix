# Installation

## Prerequisites

- `git` installed and on `PATH`
- Internet access (to fetch nixpkgs, home-manager, and binary caches)
- On Linux or WSL: `sudo` access for `apt` and mount operations

No other software is required. The bootstrap process installs Nix and everything else from the flake.

## One-Command Bootstrap

```bash
git clone https://github.com/vanillacake369/my-nixos.git && cd my-nixos
just bootstrap
```

`just bootstrap` runs the full setup sequence in order: install Nix, link `nix.conf`, install home-manager, install `uidmap` (Linux/WSL only), apply the configuration, authenticate AI providers, and run garbage collection.

## Step-by-Step Alternative

If you prefer to control each step or debug a partial installation:

```bash
# 1. Install the Nix daemon
just install-nix

# 2. Symlink dotfiles/nix/nix.conf into /etc/nix/nix.conf
#    Enables flakes, sets binary caches, configures cores/jobs
just system-link-nix-conf

# 3. Bootstrap home-manager (skipped if already present)
just install-home-manager

# 4. Apply the configuration for the detected platform
just apply

# 5. Authenticate all AI providers via cli-proxy-api OAuth
just agent-login

# 6. Run conditional garbage collection
just gc
```

## What `just apply` Does

`apply` detects the current platform by inspecting `uname` and `/proc/version`, then selects the matching flake output and runs `home-manager switch`:

```
just apply
  └── apply-validate   # abort on unsupported platform or arch
  └── apply-system     # nixos-rebuild switch (NixOS only)
  └── apply-home       # home-manager switch --flake .#<target>
  └── sync-local-integrations
        └── apply-fish              # register fish in /etc/shells, set as default
        └── reload-aerospace-if-needed   # macOS only
        └── setup-mac-power-schedule     # macOS only
```

## Flake Targets

| Platform | Flake Target |
|---|---|
| macOS (Apple Silicon) | `hm-aarch64-darwin` |
| macOS (Intel) | `hm-x86_64-darwin` |
| NixOS | `hm-nixos-x86_64-linux` |
| WSL | `hm-wsl-x86_64-linux` |
| Linux | `hm-x86_64-linux` |

The target is selected automatically. To override:

```bash
just apply aarch64-darwin
```

## Verifying the Installation

After `just apply` completes:

```bash
# List all packages managed by home-manager
home-manager packages

# Verify the flake evaluates without errors
nix flake check

# Run the built-in guard test suite
just test

# Confirm fish is the default shell
echo $SHELL
```

A successful install produces no errors from `nix flake check` and prints `N/N guard tests passed` from `just test`.
