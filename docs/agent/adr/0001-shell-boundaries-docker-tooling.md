# ADR-0001: Cohesive Shell Ownership and Split Docker Language Services

## Status

Accepted — 2026-10-22

## Context

`utils.hm.nix` contained monitoring, Git, and Zellij executables despite
dedicated modules owning their behavior. Dockerfile editing had Treesitter and
Hadolint support, while a Dockerfile LSP executable/configuration was absent.
Compose and YAML already have distinct language-service responsibilities.

## Decision

- Remove the standalone monitor module and put its generic CLI tools in
  `utils.hm.nix`; preserve its platform guards.
- Put Git/GitHub tooling in `git.hm.nix`, and put the base Zellij executable in
  `zellij.hm.nix`.
- Add `dockerfile-language-server` in `tonys-nix`, then configure `dockerls`
  with `docker-langserver --stdio` in `tonys-nvim`.
- Keep the Compose-specific LSP and Yamlls rather than replacing both with
  Docker's combined language server.

## Alternatives Considered

1. Keep every executable in `utils.hm.nix`.
   Rejected: configuration and binary ownership stay separated, making future
   changes difficult to discover.
2. Use Docker's combined Go language server for Dockerfile and Compose.
   Rejected: it overlaps the existing Compose service and Yamlls and can create
   duplicate diagnostics; it also expands the change beyond the requested
   Dockerfile LSP.
3. Add only the Dockerfile LSP binary.
   Rejected: an unconfigured executable gives Neovim no LSP client.

## Consequences

The module tree becomes easier to navigate, and all Dockerfile editor features
are available from Nix-provided binaries. The older Node-based Dockerfile LSP
is intentionally retained because it is packaged in the locked nixpkgs and
maps directly to nvim-lspconfig's `dockerls` configuration.

## Validation and Rollback

Guard tests assert package and server declarations; Lua syntax validates the
language slice. Reverting this ADR's implementation restores the deleted
module and removes the LSP declaration without data migration or external
state changes.
