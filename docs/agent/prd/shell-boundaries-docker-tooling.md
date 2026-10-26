# PRD: Shell Module Boundaries and Docker Tooling

## Objective

Make each Home Manager shell module own its cohesive runtime tools, and provide
consistent Dockerfile and Compose editing support from `tonys-nix` and
`tonys-nvim`.

## Requirements

### FR-018: Shell module ownership

- `modules/shell/monitor.hm.nix` is removed.
- Its monitoring and diagnostic packages move to `utils.hm.nix`, retaining the
  existing Linux and non-WSL platform guards.
- Git/GitHub CLI tools move from `utils.hm.nix` to `git.hm.nix`, next to their
  declarative Git and LazyGit configuration.
- The `zellij` executable moves from `utils.hm.nix` to `zellij.hm.nix`, next to
  its wrapper, runtime scripts, plugins, and configuration.

### FR-019: Docker authoring tools

- The Nix language tool table provides `dockerfile-language-server`, Hadolint,
  and the existing Docker Compose language service.
- `tonys-nvim` starts `docker-langserver --stdio` for `dockerfile` buffers.
- `tonys-nvim` retains the Compose-specific language server for
  `yaml.docker-compose` and retains Yamlls for YAML schemas.
- Dockerfile buffers use the `dockerfile` Treesitter parser and Hadolint.

## Non-goals

- Replacing the Compose-specific server with Docker's combined language server.
- Installing or managing Docker/Podman daemons.
- Changing existing Git, LazyGit, Zellij, Yamlls, or formatter behavior.

## Dependencies

- Home Manager automatic `*.hm.nix` discovery.
- nixpkgs `dockerfile-language-server` (verified in the locked input as
  `dockerfile-language-server-0.15.0`).
- Existing `neovim/nvim-lspconfig`, `nvim-treesitter`, and `nvim-lint` wiring.

## Acceptance Criteria

- [ ] No `monitor.hm.nix` module remains; the platform-aware monitoring tools
  remain available through `utils.hm.nix`.
- [ ] No Git or Zellij runtime package is duplicated between its owner module
  and `utils.hm.nix`.
- [ ] `dockerfile-language-server` is included in the Docker tool set.
- [ ] The Docker language slice configures `dockerls` with
  `docker-langserver --stdio` and `dockerfile` filetype.
- [ ] Compose LSP, Yamlls, Dockerfile Treesitter, and Hadolint remain enabled.
- [ ] Nix guard tests and focused Lua syntax checks pass.

## Verification Plan

- Add a Nix guard test that asserts ownership boundaries and Docker tool
  declarations.
- Run `just _test-guard` and `just lint` in `tonys-nix`.
- Run `luac -p lua/plugins/lang/docker.lua` in `tonys-nvim`.
