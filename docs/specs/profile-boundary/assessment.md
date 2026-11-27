# Host and profile ownership assessment

Assessed 2026-11-27 against clean commit `1b3dcce62ad3c81aff6eef9b483a1e1c194c6e21`.
Local Nix: 2.35.2. The tracked `flake.lock` pins Home Manager at
`2b13c9cb3aa20653e6f8ee0b7f8331a53ea9b0a9`, nix-darwin at
`663d8b962a11cda261b6e9f14e03911fac94baf0`, and nixpkgs at
`1a08097fc1ed85575db39763b2c4a5d8970a37ba`.

## Verdict and decision question

Move user profiles to top-level `profiles/` and reserve `nodes/` for NixOS and
nix-darwin host entrypoints. Does this remove the mixed ownership in `nodes/`
without changing flake output names, login identities, activation behavior, or
host selection? The user selected this boundary after comparing it with nested
`nodes/hosts/` and `nodes/profiles/` and retaining the current layout.

Success means that `nodes/` contains only host entrypoints, `profiles/` contains
only profile data, every direct path consumer uses the new location, existing
public outputs and identities evaluate identically, `flake.lock` stays unchanged,
and no host or home activation runs. Package versions, module behavior, local
machine files, and secrets are outside this change.

## AS-IS evidence

`nodes/personal.nix` and `nodes/vpplab.nix` are profile data; the former exposes
both `personal` and the legacy `limjihoon` output key. `nodes/tony.nixos.nix`
and `nodes/tonys-mac.darwin.nix` are system modules. `flake.nix` passes `./nodes`
to `lib/collect-user-profiles.nix` but imports system nodes by explicit path.
The collector's regular, dot-free `*.nix` filter prevents accidental import of
system modules. This is a working filename convention, but the directory has two
owners (`flake.nix`, `lib/collect-user-profiles.nix`, `nodes/*` at the pinned rev).

Direct profile path consumers are `recipes/apply.just`,
`completions/just-tonys-nix.fish`, `tests/guard/nodes.test.nix`,
`tests/hooks/just-ux.bats`, and `README.md`. Host paths also appear in
`flake.nix`, `recipes/apply.just`, `tests/guard/nodes.test.nix`,
`tests/hooks/macos-sync.bats`, and `README.md`. Existing offline evaluation
returned 27 `personal`, `limjihoon`, and `vpplab` Home Manager output names;
`hm-personal-aarch64-darwin` evaluated to user `limjihoon` and home
`/Users/limjihoon`. Darwin Homebrew user evaluated to `limjihoon`; NixOS state
version evaluated to `24.11`. Baseline `just _test-guard` passed 65/65 and
`just test-hooks` passed 83/83, each with exit 0.

The comments in `docs/specs/flat-layout/` deliberately assigned both roles to
`nodes/`. This decision supersedes that specific boundary; the earlier migration
history and its observed checks remain historical evidence.

## Comparable prior art

The [Home Manager standalone flake guide](https://nix-community.github.io/home-manager/nix-flakes/standalone.html)
(current manual, retrieved 2026-11-27) composes a Home Manager configuration
from an explicit `modules` list. It supports the conclusion that a repository
can choose its own profile file paths; it does not prescribe `profiles/` or this
repository's alias keys. The [NixOS system configuration guide](https://wiki.nixos.org/wiki/NixOS_system_configuration)
(official wiki, retrieved 2026-11-27) selects a host configuration through
`nixosConfigurations` and an explicit module path. It matches this repository's
host wiring but does not settle where profile data should live. The locked
input revisions above remain the execution source; current upstream pages are
design examples, not proof of behavior at those revisions.

## Options and trade-offs

| Option | Correctness and coupling | Cognitive load and migration | Operations, security, portability, performance |
| --- | --- | --- | --- |
| Keep AS-IS | Existing filename filter works; two owners remain in `nodes/` | No migration; contributor must remember suffix rule | No change; performance benefit `UNMEASURED` |
| `nodes/hosts/` plus `nodes/profiles/` | Explicit folders; all current relative host paths also move | More path edits and depth for no new behavior | Same activation and public data boundary; performance `UNMEASURED` |
| `nodes/` hosts plus `profiles/` users | Each root has one owner; host imports stay put | Change profile path consumers and docs; review Git renames | No activation or secret handling change; paths remain portable; performance `UNMEASURED` |

The selected option is the smallest one that gives each role a directory while
keeping host paths stable. Directory separation is an ownership aid, not a
correctness or speed claim. New profile files are still Git-backed flake inputs
and must be tracked before use.

## TO-BE, feasibility, and validation

`flake.nix` imports profiles from `./profiles` through the existing
`lib/collect-user-profiles.nix` function. `lib/mk-home-entries.nix` retains the
same key and alias rules. `nodes/` keeps only platform-specific system modules.
Just preflight and Fish completion read `profiles/*.nix`. No new registry,
abstraction, flake input, or activation path is introduced.

Validate ownership by listing tracked files and asserting collector inputs.
Validate output compatibility by comparing Home Manager attribute names and
evaluating `home.username` and `home.homeDirectory` for both aliases. Validate
host compatibility through focused Darwin and NixOS evaluation and existing
host-selection tests. Run lint, guard, and Bats checks for direct path consumers.
Use `--offline --no-update-lock-file` for focused Nix evaluation. Check
`git diff -- flake.lock` and `git diff --check` before committing. These checks
cannot establish runtime activation equivalence; that remains `UNRESOLVED` until
the normal host workflow applies the configuration.

## Migration and rollback

M1: commit this assessment and acceptance contract. M2: move two profile files,
update direct consumers, run checks, and commit the implementation. Revert M2
to restore the original paths and consumers; M1 is documentation only. No
machine state or remote resources are changed by either milestone. A rollback
after activation would need separate host-specific evaluation.

## Unresolved evidence

The maintenance benefit is a structural judgment, not measured contributor
time. No Linux, WSL, NixOS, or Darwin activation is run. No execution benchmark
supports a performance claim.
