# Package role layout assessment

Decision: keep one flat `pkgs/` directory and name each overlay for the package
or shared policy it owns. Split the mixed `language.overlay.nix`; do not add a
second discovery system or a new flake input.

## Decision question and evidence

At clean local revision `d5272032718da4274b86088b430c942fc3315693`:
should `pkgs/` retain four broad overlays, gain role-named overlays, or become
separate `pkgs/` and `overlays/` trees? Success means a reader can find an
override by role, existing package attributes and platform behavior survive,
overlay order remains deterministic, and `flake.lock` stays unchanged. Deployment
and package upgrades are outside this change.

**AS-IS (VERIFIED).** `flake.nix` passes `./pkgs` to
`lib/collect-flake-overlays.nix`. `lib/collect-overlays.nix` imports regular
`*.overlay.nix` files in sorted traversal order. Four overlays are collected.
`pkgs/language.overlay.nix` (250 lines) combines Java runtime and editor tools,
Terraform, Node tools, Bear, Lua MobDebug, and Python LSP. The other files own
Wayland IME, Jetendard, and Zellij packages. `tests/guard/overlays.test.nix`
reads three overlay paths directly; `tests/zellij/config-navigation.test.nix`
reads the fourth. `lib/collect-flake-overlays.nix` places the Rust toolchain
before local overlays and the Neovim pin after them.

**Comparable repositories (VERIFIED, read-only SSH on 2026-11-27).** At
`tonys-mac-air:~/dev/alina-seoul-talk`, revision
`e9f322abed7ac11242fc59e150fb79b07825f59c`, tracked roots `app/`,
`platform/`, and `infra/` describe their jobs; the root `justfile` imports each
role. At `tonys-mac-air:~/dev/tonys-aws`, revision
`8868fada4f77b11284459b01425d87200e9bfca1`, `infra/aws/`,
`infra/telemetry/`, and `infra/tf/` have matching Just modules. Both worktrees
had unrelated local changes; only `HEAD` trees and files were used. These
repositories support role-oriented names and shallow grouping, but use Compose
and Terraform rather than Nix overlays, so their loader semantics do not transfer.

The [Nixpkgs overlays manual](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
defines overlays as ordered `final: prev:` functions returning package sets. It
shows both new packages and overrides in an overlay. This supports preserving
the current loader and exported attributes; it does not require separate
`pkgs/` and `overlays/` trees.

## Options and feasibility

| Option | Finding |
| --- | --- |
| Keep four files | Zero migration risk, but `language` still hides six unrelated policies and `apps`/`fonts` obscure the owned behavior. |
| Flat role-named overlays | Small path-only migration for three files and a mechanical split of `language`; existing discovery and flake interface remain. Recommended. |
| Separate package recipes and overlays | Clearer distinction for local derivations, but adds a directory and `callPackage` wiring across several coupled definitions. No consumer needs this boundary today. |

No runtime or performance gain is claimed (UNMEASURED). The main costs are more
files, test path updates, and a possible change in local overlay order. No two
local overlays write the same top-level attribute at this revision, so the
reordering should preserve their result; evaluation must verify this inference.
No credentials or remote files are changed. Rollback is a Git revert of the
implementation commit. The host activation boundary remains untouched.

## TO-BE and validation

Keep `pkgs/*.overlay.nix` as the only local discovery contract. Use names that
point to an owned package or coherent policy: `wayland-ime`, `jetendard`,
`java`, `terraform`, `node-tooling`, `bear`, `lua-debugger`, `python-lsp`, and
`zellij`. Keep Java runtime selection and Java tools together because both
consume the same pinned JDKs. Keep Zellij packages together because they share
the Rust/Wasm toolchain and source tree. Do not change exported attribute names.

Validation: check the ordered overlay names and one owner for every relevant
attribute; run guard tests, formatting/lint, and the existing flake checks for
the local system; compare package derivation paths for representative attributes
before and after. Verify `flake.lock` has no diff. Linux and Darwin activation
are not part of this refactor.

Unresolved: remote repositories are role-naming examples, not direct Nix
equivalents. Linux build behavior remains dependent on the normal Linux CI.
