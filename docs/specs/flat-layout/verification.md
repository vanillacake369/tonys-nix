# Flat layout verification and code axiom review

This records the earlier four-overlay milestone. The current role-named overlay
layout is specified in `docs/specs/pkg-role-layout/`.

Assessment base: `afe2c93e118ec3c7fb762d6f39eb434fd79df0a4`. M1: `2e18c27`.
M2: `b850035`. M3 observations below are from the staged working tree before its
commit on 2026-11-26, Asia/Seoul.

| Invariant | Code evidence | Observed behavior | Static/manual check | Exception | Risk | Decision | Validation state | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Profile identity and output keys survive | `nodes/personal.nix`, `lib/mk-home-entries.nix`, `recipes/apply.just` | `hm-personal-*` and `hm-limjihoon-*` exist; both use `limjihoon`; Just resolves old WSL target | `tests/guard/nodes.test.nix`, `tests/hooks/just-ux.bats`, focused `nix eval` | Explicit `limjihoon` to `personal` recipe map preserves pre-bootstrap checks | Adding another alias needs the same routing update | Keep explicit mapping | VERIFIED | Keep alias contract in future profile edits |
| Module platform boundaries hold | `lib/discover-modules.nix`, `modules/desktop.home.nix`, `modules/wsl.home.nix` | Darwin has neither WSL activation nor Hyprland file; WSL has both Windows copy actions; NixOS has Hyprland file | Focused `nix eval` of session variables, activation keys, and home files | Conditional modules are discovered on all platforms but guarded by `mkIf` | Real activation on other OSes not observed | Accept pure evaluation boundary | VERIFIED for evaluation; activation NOT_RUN | Validate on next WSL/NixOS apply |
| Overlay ownership and order hold | `flake.nix`, `lib/collect-flake-overlays.nix`, `pkgs/*.overlay.nix` | Four local overlays collected; Darwin Home Manager activation packages built | `tests/guard/overlays.test.nix`, `just check all` | Pin overlays stay in `lib/collect-flake-overlays.nix` as cross-cutting inputs | Package build on Linux not observed | Retain existing order | VERIFIED on Darwin | Run normal Linux CI |
| Keymap and policy input paths resolve | `modules/keymap.home.nix`, `lib/keymap-to-*.nix`, `dotfiles/keymap/binds.toml`, `lib/{font,locale}-policy.nix` | Guard suite evaluates keymap and policy contracts | `tests/keymap/contracts.test.nix`, `tests/guard/locale-fonts.test.nix` | Pure generators remain separate from platform module | GUI tools not applied | Keep pure generators | VERIFIED for evaluation; activation NOT_RUN | Check GUI after next apply |
| Mutation boundaries remain explicit | `recipes/apply.just`, `nodes/tonys-mac.darwin.nix`, `flake.lock` | `just check all` does not activate; Bats plan tests keep host binding untouched; lock diff empty | Bats, `git diff -- flake.lock`, read of apply path | Nix checks build store paths | Host-local application remains untested | Commit refactor without activation | VERIFIED for local checks; activation NOT_RUN | Apply only through normal host workflow |

Checks observed:

- Baseline: `just _test-guard` 62/62; `just test-hooks` 83/83.
- M2: `just _test-guard` 65/65; focused Bats 28/28; `just check lint` passed;
  Nix evaluation returned `limjihoon`, `/Users/limjihoon`, and NixOS state version `24.11`.
- M3: `just check all` exited 0: deadnix, statix, Alejandra, Bats 83/83,
  guard 65/65, and `checks.aarch64-darwin.home-activations` build.
- Focused offline evaluation: Darwin WSL and Wayland flags absent; WSL display
  `:0.0` and copy actions present; NixOS Wayland flag and Hyprland file present;
  Darwin Hyprland file absent; WSL activation derivation evaluated.

No system or Home Manager activation ran. This is `VERIFIED` for the migration's
local acceptance criteria and `UNRESOLVED` for cross-host activation equivalence.
