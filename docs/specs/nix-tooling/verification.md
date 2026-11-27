# Selective Nix tooling verification

Assessment base: `3f4aef350ba3f06f672f31154556ae5054731ad0`.
Assessment commit: `d1f3508`. Implementation checks below ran 2026-11-27
from a staged worktree on macOS arm64 with Nix 2.35.2. The added
`treefmt-nix` input was locked to
`b7b56d3c8833016c650ca542b1230e6130299741` (2026-11-25), and its
`nixpkgs` input follows the existing root pin.

| Invariant | Code evidence | Observed behavior | Static/manual check | Exception | Risk | Decision | Validation state | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| One Alejandra policy drives formatting and checking | `treefmt.nix`, `flake.nix`, `recipes/check.just` | `formatter` and `checks.*.formatting` evaluate on Darwin, x86 Linux, and arm Linux; Darwin formatting check builds | Focused `nix eval`; `nix build .#checks.aarch64-darwin.formatting`; `just check lint` | Deadnix and statix remain separate tools because they are linters | New pinned source and formatter closure | Keep a single Alejandra definition | VERIFIED for evaluated outputs and Darwin build; Linux builds NOT_RUN | Let Linux CI build its check |
| A formatting violation stops the check | `treefmt.nix`, upstream `build.check` | A tracked malformed `formatter-negative.nix` in an isolated local clone caused the check to exit nonzero with a one-line diff | Negative `nix build .#checks.aarch64-darwin.formatting` | The test clone was temporary and did not change the active worktree | `path:.` includes this linked worktree's `.git` pointer and causes upstream check Git initialization to fail | Use normal Git flake `.#` for this repository | VERIFIED for Git flake check; `path:.` compatibility UNRESOLVED | Keep documented limitation; avoid path flake for formatting check |
| Existing configurations keep their public identity | `flake.nix`, `profiles/personal.nix`, `nodes/*.nix` | 27 Home Manager names remain; both `personal` and `limjihoon` Darwin aliases exist; `limjihoon`, Darwin Homebrew user, and NixOS state version `24.11` evaluate unchanged | Focused offline `nix eval` | No activation performed | Activation behavior not observed | Preserve configuration composition | VERIFIED for evaluation; activation NOT_RUN | Check on normal host apply |
| Existing quality gates still run | `recipes/check.just`, `tests/`, `.github/workflows/ci.yml` | `just check all` exited 0: deadnix, statix, formatting, Bats 84/84, guards 66/66, and Darwin home-activations build | Full local gate | Linux CI not run locally | New formatter check adds a build to lint | Retain the existing Just/CI entrypoints | VERIFIED on Darwin; Linux CI NOT_RUN | Observe next Linux CI |
| Dependency and state effects stay bounded | `flake.lock`, `flake.nix`, staged diff | Lock diff adds only `treefmt-nix` and its follow edge; no existing input revision changed | `git diff HEAD -- flake.lock`; `git diff --check` | Nix fetched tool source and build inputs into the local store/cache | Reverting implementation restores old input graph; Nix store is separately garbage collected | Keep pin and no activation | VERIFIED for checkout diff; remote activation NOT_RUN | Revert implementation commit if needed |

The first positive build attempted `path:.#checks.aarch64-darwin.formatting`
and exited 128 because the copied source contained this linked worktree's
`.git` pointer. The normal Git flake reference `.#checks.aarch64-darwin.formatting`
exited 0 after correcting one Alejandra style difference. This failure is
source-reference-specific, not evidence of a formatter defect.

Maintenance time and evaluation-speed benefits remain `UNMEASURED`. The Linux
formatting check was evaluated but not built on the Darwin host.
