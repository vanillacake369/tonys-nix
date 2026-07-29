[![CI](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/vanillacake369/tonys-nix/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Nix Flake](https://img.shields.io/badge/nix-flake-blue?logo=nixos)](https://nixos.wiki/wiki/Flakes)

# tonys-nix

Personal multi-platform Nix configuration for development machines, with a typed agent policy contract for Claude Code, Gemini CLI, and OpenAI Codex.

## What This Manages

- NixOS, macOS, WSL, and Linux home-manager environments.
- Shell, CLI tools, language tooling, Neovim, keymaps, and platform-specific apps.
- Claude/Gemini/Codex settings, hooks, MCP servers, roles, and workflow bindings.
- Agent guardrails encoded as Nix module contracts and build-time assertions.

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

`modules/agents/` is the executable source of truth for agent behavior:

- `policy-contract.nix` defines the typed provider-neutral contract.
- `policy-assertions.nix` fails builds for invalid policy combinations.
- `policy-*.nix` files generate enforcement hooks.
- `providers/claude/module.nix`, `providers/gemini/module.nix`, and
  `providers/codex/module.nix` adapt the contract to each provider.
- `specs/` contains portable policy, tool, telemetry, eval, and memory specs that must map back to the Nix contract.

## Agent Harness

The agent system follows one rule: provider-specific files are adapters, not the source of truth.

| Layer | Location |
|---|---|
| Executable contract | `modules/agents/policy-contract.nix` |
| Build-time assertions | `modules/agents/policy-assertions.nix` |
| Provider adapters | `modules/agents/{claude,gemini,codex}.nix` |
| Portable specs | `modules/agents/specs/` |
| Claude provider artifacts | `modules/agents/providers/claude/` |

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

Before changing agent policy, read `modules/agents/specs/README.md` and keep changes mapped to `agentPolicy.*`.

Before submitting changes:

```bash
just lint
just test
```

## License

[MIT](LICENSE)
