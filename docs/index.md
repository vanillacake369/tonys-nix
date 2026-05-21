# tonys-nix

A declarative developer environment and AI agent orchestration harness, built on Nix flakes.

---

tonys-nix manages a complete developer environment — packages, shell, editor, keymaps, and platform quirks — across NixOS, macOS (Apple Silicon and Intel), WSL, and plain Linux. A single `just apply` command bootstraps from zero to a fully configured system, regardless of which of the five supported platforms you are on. Every package version, shell alias, and editor plugin is pinned and reproducible. If it builds on one machine, it builds on all of them.

What separates this repository from an ordinary dotfiles setup is the agent layer. The same `nix build` that installs your packages also validates policy contracts for Claude Code, Gemini CLI, and OpenAI Codex. Those contracts are not README instructions — they are typed Nix options. An agent missing a required peer-review provider, or a phase gate configured with an empty tool list, causes `nix build` to fail with a descriptive error before any hook script reaches a provider's settings file. The rules cannot be skipped because the environment literally does not build until they are satisfied.

---

<div class="grid cards" markdown>

-   **Get Started**

    ---

    Bootstrap your environment in one command. Supports NixOS, macOS (Apple Silicon and Intel), WSL, and Linux.

    [:octicons-arrow-right-24: Installation](getting-started/installation.md)

-   **Understand**

    ---

    Learn the architecture, module system, and the design philosophy behind encoding agent guardrails as build-time contracts.

    [:octicons-arrow-right-24: Philosophy](concepts/philosophy.md)

-   **Configure Agents**

    ---

    Set up Claude Code, Gemini CLI, and Codex orchestration with policy contracts, hooks, and MCP servers.

    [:octicons-arrow-right-24: Agent Orchestration](agents/overview.md)

-   **Reference**

    ---

    Hook pipeline event table, package categories, environment variables, and command reference.

    [:octicons-arrow-right-24: Hook Pipeline](reference/hooks.md)

</div>

---

## Quick Links

| Section | Page | Description |
|---|---|---|
| Getting Started | [Installation](getting-started/installation.md) | Bootstrap from zero to working environment |
| Getting Started | [Platforms](getting-started/platforms.md) | NixOS, WSL, macOS, Linux specifics |
| Getting Started | [Commands](getting-started/commands.md) | Justfile task reference |
| Concepts | [Philosophy](concepts/philosophy.md) | Why this exists and the design principles behind it |
| Concepts | [How Nix Powers This](concepts/how-nix-works.md) | Flakes, overlays, activation scripts, and the module system |
| Concepts | [Agent Orchestration](concepts/agent-orchestration.md) | Multi-provider model, orchestrator pattern, policy as code |
| Architecture | [Overview](architecture/overview.md) | Repository layout and flake structure |
| Architecture | [Module System](architecture/module-system.md) | How modules, overlays, and lib/ work |
| Architecture | [Agent Policy Contract](architecture/agent-policy-contract.md) | Contract-based policy system via Nix modules |
| Agents | [Orchestration](agents/overview.md) | Multi-provider architecture |
| Agents | [Claude Code](agents/claude.md) | Hooks, commands, skills, sub-agents |
| Agents | [Gemini CLI](agents/gemini.md) | Research and critique configuration |
| Agents | [Codex](agents/codex.md) | Logic verification configuration |
| Reference | [Hook Pipeline](reference/hooks.md) | All hooks with event, matcher, and purpose |
| Reference | [Packages](reference/packages.md) | Package categories and modules |
| Guides | [Troubleshooting](guides/troubleshooting.md) | Common issues and solutions |
