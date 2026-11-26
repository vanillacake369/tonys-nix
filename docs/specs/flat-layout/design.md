# Flat Nix layout design assessment

## Verdict and decision question

Adopt the requested flat layout with narrowly scoped support files in `lib/` and
`dotfiles/`. Can this make entrypoint and package ownership visible without changing
the currently exposed machine configurations and activation behavior?

## AS-IS evidence

At `afe2c93e`, `flake.nix` composes `home.nix`, `configuration.nix`,
`hosts/tonys-mac.nix`, `user/*.nix`, and recursively discovered
`modules/**/*.hm.nix` and `modules/**/*.nixos.nix`. The local overlay collector
recurses into `modules/`. `recipes/apply.just` and Fish completion inspect tracked
`user/` and `hosts/` paths. Tests read many module files by path. These are direct
path contracts, not merely presentation (`flake.nix`, `lib/discover-modules.nix`,
`lib/collect-overlays.nix`, `recipes/apply.just`, `tests/guard/entrypoints.test.nix`).

The keymap generators consume `modules/keymap/binds.toml`; NixOS Home Manager
adds `modules/desktop/hyprland.nix`; WSL adds `modules/system/wsl.nix`; font and
locale policy values are imported by multiple modules. Moving only entrypoint files
would leave broken relative paths (`home.nix`, `modules/keymap/keymap.hm.nix`,
`modules/packages/fonts.hm.nix`, `modules/system/locale.hm.nix`).

## Comparable prior art

The [Home Manager standalone flake guide](https://nix-community.github.io/home-manager/nix-flakes/standalone.html)
shows `homeManagerConfiguration` receiving an explicit `modules` list and
`extraSpecialArgs`. This supports moving composition into `lib/mk-home-config.nix`;
it does not prescribe this repository's filenames. The [Home Manager module
reference](https://nix-community.github.io/home-manager/options/home-manager/_module.html)
explains that `imports` is resolved before module values, so conditional entrypoints
must be selected at composition time or guarded with module arguments.

## Options and trade-offs

| Option | Correctness and coupling | Migration and rollback | Cost |
| --- | --- | --- | --- |
| Retain AS-IS | Already validated; folder ownership remains implicit | None | Lowest |
| Flat `nodes/`, `modules/`, `pkgs/` | Explicit platform and package boundaries; every path consumer must move together | Git rename history and one-commit-per-milestone rollback | Moderate, concentrated in tests and recipes |

Both have unmeasured runtime benefit (`UNMEASURED`); this is an organization and
maintenance decision. Flat layout is feasible because discovery and overlay
collection already take a directory parameter, while recipe path checks are local.

## TO-BE boundary and ownership

`flake.nix` selects named nodes and discovered Home Manager modules, passes those
modules to `lib/mk-home-config.nix`, and asks `lib/collect-flake-overlays.nix` for
`pkgs/` overlays.
`nodes/tony.nixos.nix` owns NixOS bootstrap and discovers NixOS modules.
`nodes/tonys-mac.darwin.nix` owns the shared Darwin options. `nodes/personal.nix`
keeps `username = "limjihoon"`; `lib/mk-home-entries.nix` exposes both the historical
login key and the new `personal` key. `recipes/apply.just` resolves the login through
the tracked profile metadata before selecting a flake output.

`modules/*.home.nix` and `modules/*.nixos.nix` contain behavior. Standalone policy
values and keymap renderers move to `lib/`; the keymap TOML moves to `dotfiles/`.
The conditional NixOS desktop and WSL Home Manager modules remain separate modules
because their imports must only apply to their matching target. No empty Darwin
network module is created: no Darwin system network behavior exists at this revision.

## Validation, migration, and rollback

The claimed ownership benefit is observable in the file map and discovery tests.
Behavioral equivalence is checked by guard and Bats tests plus output-name,
`home.username`, Darwin Homebrew, and NixOS option evaluation. Lint checks syntax
and style; it cannot prove activation behavior. Builds may materialize Nix store
paths; no activation runs. Each milestone is independently committed and can be
reverted in reverse order. Rollback of this repository refactor does not roll back
an already activated system, so activation is outside scope.

## Unresolved evidence

No Linux, WSL, or Darwin activation is performed in this task. Runtime activation
equivalence remains `UNRESOLVED` until the relevant host applies the configuration.
