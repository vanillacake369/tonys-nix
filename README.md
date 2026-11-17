[![CI](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue?logo=nixos)](https://nixos.wiki/wiki/Flakes)

# tonys-nix

Personal multi-platform Nix configuration for development machines, including
shell, language tooling, and platform integration configuration.

## What This Manages

- NixOS, macOS, WSL, and Linux home-manager environments.
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

The default `just` path is intentionally bootstrappable: it checks or installs
Nix, prepares the repository `nix.conf`, verifies the Home Manager execution
path, runs the fast core gate, and then applies the selected profile.

The current login name (`id -un`) selects `user/<login>.nix`. Profile files are
exported as named flake outputs such as `hm-<profile>-aarch64-darwin`; there is no
implicit default profile. Run the repository-level `just` command without
`sudo`. A missing or untracked profile is rejected before activation with
creation or `git add` guidance.

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

`Brewfile` is the additive shared baseline for the Apple Silicon Macs. It does
not remove host-specific software or pin Homebrew's rolling package versions.

```bash
just sync brew export                # target -> candidate Brewfile
just sync brew import                # repo Brewfile -> local Mac, additive
just sync brew import user@host      # repo Brewfile -> remote Mac
just sync brew check user@host       # verify the explicit remote target
```

Use `local` (the default) for the current Mac or pass any explicit
`[user@]tailscale-host` target. The repository does not embed machine names,
account names, or remote home-directory paths.

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
