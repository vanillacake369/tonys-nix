# Host and profile boundary verification

Assessment base: clean `92bea18cbe6ef7f5fd206a6315bd8aaa5193123d`.
M1 assessment commit: `c66c95e`. M2 results below were observed on
2026-11-27 before its implementation commit. No host or Home Manager activation
was performed.

| Invariant | Code evidence | Observed behavior | Static/manual check | Exception | Risk | Decision | Validation state | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Host and profile files have separate owners | `nodes/*.nixos.nix`, `nodes/*.darwin.nix`, `profiles/*.nix`, `flake.nix`, `lib/collect-user-profiles.nix` | Only host entrypoints remain in `nodes/`; collector reads `profiles/` | `tests/guard/nodes.test.nix`; guard 66/66 | The collector still rejects dotted and backup names, keeping deterministic discovery | New profile files must be tracked in Git | Keep current collector and separate roots | VERIFIED for source and evaluation | Keep new profiles in `profiles/` |
| Public Home Manager outputs and login identity stay stable | `profiles/personal.nix`, `lib/mk-home-entries.nix`, `recipes/apply.just` | 27 output names remain; both `hm-personal-*` and `hm-limjihoon-*` exist; `limjihoon` and `/Users/limjihoon` evaluate unchanged | Focused offline `nix eval`; Bats 84/84 | `personal` is an alias for the `limjihoon` login | Adding aliases needs equivalent Just routing | Keep alias contract | VERIFIED for evaluation | Exercise normal activation on next host apply |
| Missing outputs fail with a usable profile path | `recipes/apply.just` | Error points `limjihoon` to `profiles/personal.nix` | Bats missing-output fixture | The previous message referenced an unset `profile_key` in `_home-target` | Only the failure branch changed | Resolve alias in `_home-target` | VERIFIED | None |
| Host configuration and lock state stay stable | `flake.nix`, `nodes/tony.nixos.nix`, `nodes/tonys-mac.darwin.nix`, `flake.lock` | Darwin Homebrew user remains `limjihoon`; NixOS state version remains `24.11`; lockfile diff is empty | Focused offline `nix eval`; `git diff -- flake.lock` | Nix evaluation can populate the local store/cache | Host activation equivalence is not observed | Keep host paths and inputs unchanged | VERIFIED for evaluation; activation NOT_RUN | Check on next normal host apply |
| Direct path consumers use the new profile root | `recipes/apply.just`, `completions/just-tonys-nix.fish`, `README.md`, tests | Just and Fish tests pass against `profiles/`; lint passes | Bats 84/84, guard 66/66, deadnix, statix, Alejandra, `git diff --check` | Historical `docs/specs/flat-layout/` records the earlier boundary | A future path change must update direct consumers together | Keep prior design as historical record | VERIFIED for local checks | None |

All listed commands exited 0. Focused evaluations used `--offline
--no-update-lock-file` with `path:.` on Nix 2.35.2. The claimed maintenance
benefit has no measured contributor-time data (`UNMEASURED`). Runtime activation
equivalence remains `UNRESOLVED` until hosts apply the configuration normally.
