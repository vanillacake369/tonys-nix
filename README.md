[![CI](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue?logo=nixos)](https://nixos.wiki/wiki/Flakes)

# tonys-nix

Personal multi-platform Nix configuration for development machines, including
shell, language tooling, and platform integration configuration.

## What This Manages

- NixOS, nix-darwin, WSL, and Linux Home Manager environments.
- Shell, CLI tools, language tooling, Neovim, keymaps, and platform-specific apps.

## Quick Start

```bash
git clone https://github.com/vanillacake369/tonys-nix.git
cd tonys-nix
just setup all
```

For an existing checkout:

```bash
just                    # run core checks, then apply the login user's profile
just apply home         # apply only Home Manager
just check all          # run lint, hook, and flake checks without applying
```

The default `just` path first checks the platform and login profile without
changing the machine. It then checks or installs Nix, prepares the repository
`nix.conf`, verifies the Home Manager execution path, runs the fast core gate,
resolves the Home Manager output, and applies the system and home configuration.

The current login name (`id -un`) selects `user/<login>.nix`. Profile files are
exported as named flake outputs such as `hm-<profile>-aarch64-darwin`; there is no
implicit default profile. Run the repository-level `just` command without
`sudo`. A missing or untracked profile is rejected before activation with
creation or `git add` guidance.

On NixOS, `just` requires a readable `/etc/nixos/hardware-configuration.nix`
before it bootstraps or activates anything. Generate and review that file on
the target machine before the first run. The placeholder hardware values used
for cross-platform flake evaluation are never accepted by the apply path.

## Architecture In 60 Seconds

```text
flake.nix
  -> lib/mk-home-config.nix
  -> home.nix
  -> modules/*
```

Provider integrations are intentionally paused in this repository. The
preserved source and encrypted material are archived outside the Git worktree
so they can be restored deliberately if the project is resumed.

## Common Commands

```bash
just                              # prepare core runtime, check core, then apply all
just apply [all|home|system] [profile] # default profile: current login user
just check [all|core|flake|hooks|lint]
just setup <all|nix|home|mac|completions>
just maintenance gc [auto|force|status]
just image list
just image build <format>
just image build-arch <format> <arch>
```

Fish completion is installed declaratively by Home Manager. Generic Just
completion remains available everywhere; repository-specific subcommands are
added only when the current Git root has this repository's structural markers.

## macOS App Sync

`hosts/tonys-mac.nix` declares the shared Homebrew taps, formulae, and casks.
`just` selects a nix-darwin configuration only when its name matches the macOS
LocalHostName or a machine-local binding. On an unmatched Mac with one declared
configuration, the first interactive run asks to bind it; for a non-interactive
run, use `DARWIN_CONFIG=tonys-mac just` once. The binding is stored in
`~/.config/tonys-nix/hosts/<LocalHostName>/config-name` (or under
`$XDG_CONFIG_HOME/tonys-nix/hosts/`). `DARWIN_CONFIG` updates that binding.

Machine-specific, non-secret nix-darwin options belong in an optional
`darwin.nix` next to the binding file. For example, a local network privacy
exception can be declared there using `system.defaults.CustomSystemPreferences`.
`just` passes that file to nix-darwin; pure flake checks omit it. Do not put
credentials in the local module: evaluated values can appear in the Nix store.

System activation prompts for `sudo`; `just` passes the login user to
nix-darwin for Homebrew activation, and Home Manager runs as that user.
Activation installs missing entries;
it does not remove unmanaged software or upgrade existing formulae and casks.

```bash
just sync brew
```

The first activation uses the pinned nix-darwin `darwin-rebuild` app from the
flake. For another Mac with a different shared baseline, add a matching
`darwinConfigurations` output and `hosts/<name>.nix` module.

Raycast does not provide a supported headless configuration export/import CLI.
The Raycast recipes only print the supported GUI workflow and verification
checklist; they do not open deep links, transfer files, or claim that an import
completed:

```bash
just sync raycast export  # print the GUI export guide
just sync raycast import  # print the GUI import guide
just sync raycast verify  # print the manual verification checklist
```

Transfer `.rayconfig` files securely and never commit them or their passphrases.
Import is selective, must be confirmed inside Raycast, and merges data rather
than making the target Mac an exact overwrite of the source.

## Contributing

Before submitting changes:

```bash
just check all
```

## License

[MIT](LICENSE)
