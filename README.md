[![CI](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue?logo=nixos)](https://nixos.wiki/wiki/Flakes)

# tonys-nix

Personal multi-platform Nix configuration for development machines, including
shared agent instructions exported to Claude Code, Gemini CLI, and OpenAI Codex.

## What This Manages

- NixOS, macOS, WSL, and Linux home-manager environments.
- Shell, CLI tools, language tooling, Neovim, keymaps, and platform-specific apps.
- Claude/Gemini/Codex settings, MCP servers, roles, and workflow bindings.
- Shared agent guidance kept in one provider-neutral source of truth.

## Quick Start

```bash
git clone https://github.com/vanillacake369/tonys-nix.git
cd tonys-nix
just bootstrap
```

For an existing checkout:

```bash
just apply      # apply the detected platform configuration
just test       # run guard and hook tests
just lint       # deadnix, statix, alejandra
```

## Architecture In 60 Seconds

```text
flake.nix
  -> lib/mk-home-config.nix
  -> home.nix
  -> modules/*
  -> modules/agents/*
```

`modules/agents/` keeps agent behavior boring:

- A provider-neutral source of truth holds shared instructions, portable specs,
  and reusable workflow material.
- Outporters translate shared data into provider-native output shapes.
- Provider modules stay thin and should not redefine behavioral policy.

## Agent Harness

The agent system follows one rule: provider-specific files are export surfaces,
not the source of truth. Shared behavior belongs in the provider-neutral layer;
provider code may change format, naming, and integration mechanics only.

## Common Commands

```bash
just bootstrap       # first-time setup
just apply           # apply current platform
just agent-login     # authenticate AI providers
just gc              # conditional Nix garbage collection
just gc-info         # show GC state
just test            # guard + hook tests
just lint            # Nix lint and format checks
```

## Contributing

Before changing agent behavior, start from the shared source of truth and keep
provider-specific changes limited to export mechanics.

Before submitting changes:

```bash
just lint
just test
```

## License

[MIT](LICENSE)
