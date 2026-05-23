# Package Reference

All packages are declared in Nix modules. Run `home-manager packages` to see exact store paths and versions for your current profile.

## Language Toolchains — `modules/language.nix`

Language support includes the runtime, build tooling, language server, formatter, and linter for each language.

| Language | Packages |
|---|---|
| **Go** | `go`, `gotools`, `gopls`, `golangci-lint`, `delve` |
| **Java** | `zulu17` (JDK), `gradle`, `jdt-language-server`, `google-java-format`, `lombok` |
| **Rust** | `rustc`, `cargo` |
| **Python 3.13** | `python313Packages.python` (interpreter), `uv`, `pip`, `pytest`, `python-lsp-server`, `ruff` (also via `python313Packages.ruff`), `uvicorn`, `black` (also via `python313Packages.black`) |
| **Node 22 / TypeScript** | `nodejs_22`, `pnpm`, `typescript-language-server`, `prettier`, `biome` |
| **Lua 5.4** | `lua54Packages.lua`, `lua54Packages.luaunit`, `lua-language-server`, `stylua`, `selene` |
| **C / C++** | `gcc`, `clang-tools`, `bear` |
| **Bash** | `bash-language-server`, `shfmt`, `shellcheck` |
| **Nix** | `nixd`, `alejandra`, `statix`, `deadnix` |
| **YAML / TOML** | `yamllint`, `yaml-language-server`, `yamlfmt`, `taplo` |
| **Terraform** | `terraform`, `terraform-ls`, `tflint` |
| **Ansible** | `ansible` |
| **Docker** | `docker-compose-language-service`, `hadolint` |
| **HTML** | `vscode-langservers-extracted` |
| **Build tools** | `just`, `just-lsp`, `gnumake`, `tree-sitter` |

`JAVA_HOME` is set to the `zulu17` store path via `home.sessionVariables`.

---

## Applications — `modules/apps.nix`

### All Platforms

| Package | Purpose |
|---|---|
| `claude-code` | Claude Code CLI (from `llm-agents.nix` overlay) |
| `gemini-cli` | Gemini CLI |
| `codex` | OpenAI Codex CLI |

### Linux (not WSL)

| Package | Purpose |
|---|---|
| `firefox` | Web browser |
| `slack` | Team messaging |
| `ticktick` | Task management |
| `ytmdesktop` | YouTube Music desktop client |
| `libreoffice` | Office suite |
| `hunspell` + dicts | Spell check (English, Korean) |

### macOS only

| Package | Purpose |
|---|---|
| `aldente` | Battery charge limiter |
| `jankyborders` | Active window border highlight |
| `appcleaner` | Application uninstaller |
| `wezterm` | GPU-accelerated terminal emulator |
| `aerospace` | Tiling window manager |
| `hidden-bar` | Menu bar icon manager |

---

## Shell and CLI Tools — `modules/shell/`

### Core Tools (`utils.nix`)

| Package | Purpose |
|---|---|
| `bat` | `cat` with syntax highlighting |
| `jq` | JSON processor |
| `moreutils` | `sponge` and other shell utilities |
| `ripgrep` | Fast recursive search |
| `fd` | Fast `find` alternative |
| `tree` | Directory tree display |
| `curl` | HTTP client |
| `openssl` | TLS utilities |
| `lazygit` | Git TUI |
| `ghalint` | GitHub Actions linter |
| `bfg-repo-cleaner` | Git history cleaner |
| `zellij` | Terminal multiplexer |
| `fastfetch` | System info display |
| `asciinema` + `asciinema-agg` | Terminal recording |
| `redli` | Redis CLI |
| `sops` | Secret operations |
| `age` | File encryption |
| `ssh-to-age` | SSH key to age key converter |
| `git-crypt` | Git-integrated encryption |
| `git-filter-repo` | Git history rewriting |
| `gh` | GitHub CLI |
| `gnupg` | GPG toolchain |

**macOS additions:** `pngpaste`, `terminal-notifier`
**Linux additions:** `xclip`, `google-authenticator` (Linux, including WSL)

### Infrastructure Tools (`infra.nix`, macOS only)

| Package | Purpose |
|---|---|
| `awscli` | AWS CLI |
| `nuclei` | HTTP vulnerability scanner |
| `ngrok` | Localhost tunnel |

### Network Tools (`network.nix`)

Network diagnostics and utilities. See the module file for the current package list.

### Monitor Tools (`monitor.nix`)

System and process monitoring utilities. See the module file for the current package list.

### Shell Environment (`fish.nix`, `git.nix`, `editor.nix`, etc.)

These modules configure programs via `programs.<name>` rather than `home.packages`. Key programs:

| Module | Program |
|---|---|
| `fish.nix` | fish shell with abbreviations and environment |
| `git.nix` | git with delta pager |
| `editor.nix` | Neovim (LazyVim distribution) |
| `fzf.nix` | fzf with fish keybindings |
| `direnv.nix` | direnv + nix-direnv |
| `yazi.nix` | yazi terminal file manager |

---

## JetBrains IDEs — `modules/packages/jetbrains.nix`

JetBrains IDEs are declared in a dedicated module. The exact set may vary; check the file for the current list.

---

## AI Agent Infrastructure — `modules/agents/`

| Package / Service | Module | Purpose |
|---|---|---|
| `claude-code` | `apps.nix` | Claude Code CLI binary |
| `gemini-cli` | `apps.nix` | Gemini CLI binary |
| `codex` | `apps.nix` | OpenAI Codex CLI binary |
| `cli-proxy-api` | `agents/agents-proxy.nix` | OAuth proxy; routes requests to all three providers |
| MCP servers | `agents/agents-mcp.nix` | SSoT MCP server definitions, adapted per provider |

`cli-proxy-api` is managed as a `launchd` service on macOS (auto-start on login). On Linux it runs as a user systemd service.
