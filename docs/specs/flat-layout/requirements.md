# Flat Nix layout requirements

Source: `afe2c93e118ec3c7fb762d6f39eb434fd79df0a4` (clean worktree at assessment).

## Goal

Make `nodes/` own machine and user entrypoints, `modules/` own Home Manager and NixOS
modules, and `pkgs/` own local overlays. Keep `lib/`, `dotfiles/`, `secrets/`,
`tests/`, and `recipes/` in their existing roles.

## Acceptance criteria

1. `nodes/personal.nix` represents the existing `limjihoon` login, `nodes/vpplab.nix`
   represents `vpplab`, and the NixOS and Darwin entrypoints live in `nodes/`.
2. Home Manager module names use `.home.nix`; NixOS modules use `.nixos.nix`;
   Darwin system modules use `.darwin.nix`. Overlays live under `pkgs/`.
3. Existing public Home Manager output names, including `hm-limjihoon-*`, work.
   `personal` may be a new alias, but must not change the login name or home path.
4. WSL activation, NixOS Hyprland settings, keymap generation, overlay ordering,
   Darwin host binding, and optional machine local Darwin module still work.
5. `flake.lock` is unchanged. No system or home activation is performed.
6. Guard tests, Just hook tests, lint, and focused flake output evaluation pass.
7. Each milestone is committed only after its own checks pass.

## Scope

Path and discovery refactor, direct consumers, tests, and documentation. No input
updates, package version changes, secret changes, machine local file changes, or
deployment.

## Invariants

- Every module is imported once in the intended platform context.
- Profile names resolve deterministically from tracked files; `username` remains
  the activation identity. No implicit user is derived during pure flake evaluation.
- Only `pkgs/*.overlay.nix` enters the local overlay list, in deterministic order
  between the Rust toolchain and pinned Neovim overlays.
- Missing or untracked profile and Darwin node files fail before activation.
- Evaluation of `just plan` never writes the host binding.
