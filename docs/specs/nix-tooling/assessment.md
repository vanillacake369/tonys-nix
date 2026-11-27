# Selective Nix tooling assessment

Assessed 2026-11-27 at clean source revision
`3f4aef350ba3f06f672f31154556ae5054731ad0` with Nix 2.35.2.
`flake.lock` is tracked and clean. The design question is: which, if any, of
the seven proposed tools removes a concrete gap in this repository without
replacing working ownership and test contracts?

## Verdict

Adopt only `numtide/treefmt-nix` for a standard `formatter` output and a
flake formatting check, using the existing Alejandra style. Keep the six
other candidates out of the dependency graph. This is a workflow improvement;
there is no measured runtime or evaluation performance claim (`UNMEASURED`).

Success means `nix fmt` is available, the formatter check rejects malformed
tracked Nix files, `just lint` uses the same configuration, deadnix and statix
remain active, all existing Nix/Just tests pass, and Home Manager, NixOS, Darwin,
image, and overlay outputs retain their names and observed values. No activation,
host binding, secret, package version policy, or profile behavior changes.

## AS-IS evidence

`flake.nix` uses its pinned `nixpkgs.lib` and explicit `nixosConfigurations`,
`darwinConfigurations`, `homeConfigurations`, `packages`, and `checks` outputs.
`lib/discover-modules.nix` selects `.home.nix` and `.nixos.nix` modules;
`lib/collect-tests.nix` and `lib/collect-checks.nix` select separate test and
check suffixes and reject duplicate names. `tests/guard.check.nix` publishes
the current 66 guard results. `recipes/check.just` runs deadnix, statix, and
Alejandra directly; it does not expose `formatter.<system>` or a formatting
flake check. `.github/workflows/ci.yml` invokes the existing guard path.
The files above are direct code evidence at the pinned revision. The claimed
benefit of a standard formatter output is a workflow inference.

## Comparable prior art and candidate fit

The linked upstream documentation was retrieved 2026-11-27. The pages reflect
their then-current main/master branch, not a release guarantee. The eventual
`flake.lock` revision is the executable source for the selected tool.

| Candidate | Upstream behavior | Fit at this revision | Decision |
| --- | --- | --- | --- |
| [`nix-community/nixpkgs.lib`](https://github.com/nix-community/nixpkgs.lib/blob/master/flake.nix) | Cheap, separately rebased nixpkgs lib | `flake.nix` already inherits `lib` from the same pinned nixpkgs used for system evaluation; a second lib revision risks drift | Do not add |
| [`numtide/treefmt-nix`](https://github.com/numtide/treefmt-nix/blob/main/README.md) | `evalModule` produces `formatter` and `build.check` without flake-parts | Reuses current Alejandra policy while adding standard CLI and flake check | Adopt |
| [`nix-community/nix-unit`](https://github.com/nix-community/nix-unit/blob/main/README.md) | Runs `lib.debug.runTests`-style attrsets and isolates evaluator failures | Current `tests/*.test.nix` return `results` lists, so adoption requires a test protocol migration; no observed diagnostic failure warrants it | Defer |
| [`nix-community/namaka`](https://github.com/nix-community/namaka/blob/main/README.md) | Snapshot tests with review/accept workflow | Current guard checks assert semantic values; snapshots would add update/review state without a concrete high-value output snapshot | Do not add |
| [`nix-community/flakelight`](https://github.com/nix-community/flakelight/blob/master/API_GUIDE.md) | Framework for generated flake outputs and autoloaded directories | Current flake has host-local Darwin selection and platform-specific checks; conversion replaces the composition root for a formatting gap | Do not add |
| [`denful/import-tree` (formerly `vic/import-tree`)](https://github.com/denful/import-tree) | Recursively imports modules with filter/match/map | Current discovery must classify two suffixes and keep policy files out; swapping the collector is wider than needed | Do not add |
| [`nix-community/haumea`](https://github.com/nix-community/haumea) | Loads a file hierarchy as an attrset, separate from NixOS modules | Current profile, module, and check collectors have different result types and duplicate policies | Do not add |

The `vic/import-tree` GitHub URL redirected to `denful/import-tree` at review
time. Tool popularity and README examples alone do not establish a benefit for
this flake.

## Options, trade-offs, and feasibility

| Option | Correctness and coupling | Cognitive load, migration, rollback | Operations, security, portability, performance |
| --- | --- | --- | --- |
| Retain current lint | Known passing commands; no standard formatter/check output | Lowest migration cost; two ways to run formatting remain | No new input; runtime benefit `UNMEASURED` |
| Add treefmt-nix with Alejandra | One formatter definition drives `nix fmt` and flake check; deadnix/statix stay separate | One pinned input and one small config file; revert implementation commit to roll back | Check builds a sandboxed copy; no host activation; new source input affects supply chain; supports existing Linux/Darwin systems; performance `UNMEASURED` |
| Replace flake/test discovery framework | Requires re-expressing platform and duplicate contracts | High migration and rollback cost for no observed failure | More dependencies and behavior changes; performance `UNMEASURED` |

The selected tool has a standalone flake API, so neither flake-parts nor a
module discovery replacement is required. Pin its input and follow the existing
nixpkgs input to avoid a second nixpkgs revision. Maintain explicit
`flake.nix` composition and current platform boundaries.

## TO-BE and validation plan

`treefmt.nix` owns only Alejandra configuration. `flake.nix` evaluates it for
each supported system, exports `formatter.<system>`, and merges a `formatting`
derivation into existing `checks.<system>`. `recipes/check.just` retains
deadnix and statix, and invokes the flake formatting check instead of a
separate Alejandra command. This makes the same configuration authoritative
for `nix fmt` and `just lint`; no module, profile, or host configuration is
restructured.

Validation: evaluate the formatter and formatting check on Darwin and Linux;
build the check on the current host; run `just lint`, guard tests, Bats, and
focused configuration evaluations. A deliberately malformed Nix file in an
isolated temporary checkout must make the formatting check fail. Compare
selected output names and identity/state values with the pre-change values.
Inspect `flake.lock` to confirm only the new tool and its required closure
were added. Do not run `nix fmt` on the live checkout as a verification step.

## Milestones, migration, rollback, and unresolved evidence

M1: commit this assessment and the baseline contracts. M2: add the pinned
tool and wire standard formatting outputs, then verify and commit. The M2
commit can be reverted to restore previous lint behavior and input graph.
Nix builds can write local store/cache paths; neither milestone switches a
profile or host. Runtime activation equivalence and contributor-time savings
remain `UNRESOLVED` until observed in normal use. Performance improvements
remain `UNMEASURED`.
