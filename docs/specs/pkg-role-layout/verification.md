# Package role layout verification

M1: `2a5fa0a77e5fa18dfb55b1424ba7d1b0b73a562b`.
M2 evidence below was collected on the staged implementation before its commit
on 2026-11-27. No activation or remote write occurred.

| Invariant | Code evidence | Observed behavior / static check | Exception and risk | Decision / state |
| --- | --- | --- | --- | --- |
| Only role-named overlays enter the local list | `pkgs/*.overlay.nix`, `lib/collect-overlays.nix`, `tests/guard/overlays.test.nix` | Guard verifies the nine expected file names and nine overlay functions; `guard-tests` passed 67/67 | Loader still silently skips an overlay with missing required arguments, an existing behavior | Keep loader unchanged; VERIFIED |
| Existing package attributes and pins remain | Split overlays, `flake.lock` | Four baseline Darwin `.drv` paths match; all 14 attributes moved from `language.overlay.nix` have identical pre/post Darwin `.drv` paths | Package binaries were not rebuilt for every platform | Keep export names and versions; VERIFIED for evaluation |
| Cross-platform package policies still evaluate | `pkgs/java.overlay.nix`, `pkgs/terraform.overlay.nix`, `pkgs/wayland-ime.overlay.nix` and other role files | Eight representative Linux `.drv` paths evaluated; Darwin `home-activations` built in `just check all` | Full Linux NixOS system evaluation fails on deprecated Podman registry options, also at M1 | Overlay evaluation VERIFIED; Linux NixOS system UNRESOLVED outside this change |
| Dependency and state boundaries remain | `lib/collect-flake-overlays.nix`, role files | Rust overlay still precedes local overlays; pinned Neovim still follows; local overlays write distinct top-level keys. No mutable shared state or new fallback was introduced | Local file order changed, but no key collision was observed | Keep deterministic discovery; VERIFIED by static review and flake checks |
| Repository quality gate remains | `just check all`, `git diff --cached --check` | `deadnix`, `statix`, formatting, 84 Bats hooks, 67 guard tests, and Darwin `home-activations` passed | Linux package builds were not run on this Darwin host | Accept M2 with stated platform limit |

The Linux NixOS assertion was reproduced at M1 with a pinned
`git+file://...?rev=2a5fa0a...` flake reference. It names
`modules/virtualization.nixos.nix`, which this milestone did not edit. Its
fix belongs to a separate Podman configuration change, not this package naming
refactor.
