# tonys-nix

A multi-platform Nix flake and home-manager configuration that doubles as an AI agent orchestration harness. Flakes and home-manager manage the developer environment; a contract-based policy system manages the agents that operate inside it.

## What This Repository Does

This repository declares a complete developer environment — packages, shell, editor, keymaps, and platform quirks — across NixOS, WSL, macOS, and plain Linux. It also encodes policy contracts for Claude Code, Gemini CLI, and OpenAI Codex as Nix modules that generate and validate hook scripts at build time.

## Quick Links

| Section | Page | Description | Status |
|---|---|---|---|
| Getting Started | [Installation](getting-started/installation.md) | Bootstrap from zero to working environment | Active |
| Getting Started | [Platforms](getting-started/platforms.md) | NixOS, WSL, macOS, Linux specifics | Active |
| Getting Started | [Commands](getting-started/commands.md) | Justfile reference | Active |
| Architecture | [Overview](architecture/overview.md) | Repository layout and flake structure | Active |
| Architecture | [Module System](architecture/module-system.md) | How modules, overlays, and lib/ work | Active |
| Architecture | [Agent Policy Contract](architecture/agent-policy-contract.md) | DDD/OOP policy system via Nix modules | Active |
| Agents | [Orchestration](agents/overview.md) | Multi-provider architecture | Active |
| Agents | [Claude Code](agents/claude.md) | Hooks, commands, skills, sub-agents | Active |
| Reference | [Hook Pipeline](reference/hooks.md) | All hooks with event, matcher, and purpose | Active |
| Reference | [Packages](reference/packages.md) | Package categories and modules | Active |
| Guides | [Troubleshooting](guides/troubleshooting.md) | Common issues and solutions | Active |

## Doc Lifecycle

| Status | Meaning |
|---|---|
| **Active** | Current, reflects the state of the codebase |
| **Draft** | Work in progress, may contain gaps or inaccuracies |
| **Deprecated** | Superseded by a newer document; kept for historical reference |
