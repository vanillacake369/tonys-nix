# Package role layout milestones

## Specification and invariant

Source: clean `bde5ca78f1ee35c016cb714526b79ea675356055`.
Baseline `nix build --offline --no-update-lock-file
.#checks.aarch64-darwin.guard-tests --no-link` passed. On `aarch64-darwin`,
the selected baseline derivations were:

| Attribute | Baseline `.drv` store hash |
| --- | --- |
| `jetendard` | `bdf7lar6qxhvhwjw5ga7isrqf0aly3xc` |
| `javaProjectJdk` | `w15rhy26p06b7529vjznk8l1cg9aiia4` |
| `terraform` | `g87v5x4a7xqqragy5j4n5z35zjxy5q22` |
| `zellij-nav` | `il350bfdc4ip2rz6ddm68rvl16m1kxaw` |

The local overlay set exposes exactly the same package attributes and pinned
versions before and after this change. Rust remains before local overlays;
Neovim remains after them. Only tracked `pkgs/*.overlay.nix` files are imported
and `flake.lock` remains identical. No system or home activation occurs.

```mermaid
flowchart LR
  A[Pin local and remote revisions] --> B[Assess roles and Nix order]
  B --> C[M1: specification and baseline]
  C --> D[M2: role-named overlays and direct consumers]
  D --> E[Guard, lint, flake and derivation checks]
  E --> F[Code axiom review and milestone commit]
```

| Milestone | Prerequisite | Acceptance evidence | Commit |
| --- | --- | --- | --- |
| M1: assessment and specification | Clean baseline; comparable `HEAD` trees read | Decision, source revisions, options, invariants, baseline checks recorded | `docs: specify package role layout` |
| M2: role-named overlays | M1 accepted | Exported attributes, selected derivations, guard/flake/lint checks, clean lockfile diff | `refactor: name overlays by package role` |

For M2, review each invariant as `invariant | code evidence | observed behavior |
static check | exception | risk | decision | validation`. If an evaluation fails,
fix M2 before committing. Roll back M2 with its commit if a later platform check
finds a regression.
