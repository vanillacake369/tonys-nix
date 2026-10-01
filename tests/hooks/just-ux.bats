#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  JUST=(just --justfile "$REPO_ROOT/justfile")
}

@test "bare just runs core checks before applying all" {
  run "${JUST[@]}" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Preparing and checking core"* ]]
  [[ "$output" == *"just check core"* ]]
  [[ "$output" == *"just apply all"* ]]
  [[ "$output" != *"mktemp"* ]]
  [[ "$output" != *".log"* ]]
  [[ "$output" != *"just test-hooks"* ]]
  [[ "$output" != *"just _test-flake"* ]]
  check_line="$(printf '%s\n' "$output" | grep -n 'just check core' | head -1 | cut -d: -f1)"
  apply_line="$(printf '%s\n' "$output" | grep -n 'just apply all' | head -1 | cut -d: -f1)"
  [ "$check_line" -lt "$apply_line" ]
}

@test "core checks bootstrap runtime before lint and guard contracts" {
  run "${JUST[@]}" --dry-run check core
  [ "$status" -eq 0 ]
  [[ "$output" == *"core) just _bootstrap-core && just lint && just _test-guard"* ]]

  run "${JUST[@]}" --dry-run _bootstrap-core
  [ "$status" -eq 0 ]
  [[ "$output" == *"just install-nix"* ]]
  [[ "$output" == *"just system-link-nix-conf"* ]]
  [[ "$output" == *"just install-home-manager"* ]]
}

@test "core tools fall back to nix on a plain environment" {
  run "${JUST[@]}" --dry-run lint
  [ "$status" -eq 0 ]
  [[ "$output" == *'command=(nix run "nixpkgs#${package}" -- "$@")'* ]]

  run "${JUST[@]}" --dry-run _test-guard
  [ "$status" -eq 0 ]
  [[ "$output" == *"nix run nixpkgs#jq -- -r"* ]]
}

@test "apply success path uses concise console output" {
  run "${JUST[@]}" --dry-run apply all
  [ "$status" -eq 0 ]
  [[ "$output" == *'[→] Home Manager: $target'* ]]
  [[ "$output" != *"User:"* ]]
  [[ "$output" != *"Platform:"* ]]
  [[ "$output" != *"Target:"* ]]

  run "${JUST[@]}" --dry-run _apply-validate aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" != *"Apply target validated"* ]]

  run "${JUST[@]}" --dry-run _apply-system aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" != *"System apply skipped"* ]]
}

@test "home apply reclaims matching managed files before backup overwrite" {
  run "${JUST[@]}" --dry-run _apply-home hm-vpplab-aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *'just _reclaim-matching-home-files "$flake_target"'* ]]
  [[ "$output" == *"Home Manager applied"* ]]

  run "${JUST[@]}" --dry-run _reclaim-matching-home-files hm-vpplab-aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *"home-files"* ]]
  [[ "$output" == *'cmp -s "$managed" "$target"'* ]]
  [[ "$output" == *'rm -f "$target"'* ]]
}

@test "named profiles resolve to the existing output contract" {
  run "${JUST[@]}" _home-target vpplab aarch64-darwin darwin
  [ "$status" -eq 0 ]
  [ "$output" = "hm-vpplab-aarch64-darwin" ]

  run "${JUST[@]}" _home-target limjihoon x86_64-linux wsl
  [ "$status" -eq 0 ]
  [ "$output" = "hm-limjihoon-wsl-x86_64-linux" ]

  run "${JUST[@]}" _home-target vpplab x86_64-linux nixos
  [ "$status" -eq 0 ]
  [ "$output" = "hm-vpplab-nixos-x86_64-linux" ]
}

@test "missing and unsafe profiles fail with guidance" {
  run "${JUST[@]}" _home-target missing-user aarch64-darwin darwin
  [ "$status" -eq 2 ]
  [[ "$output" == *"user/missing-user.nix"* ]]
  [[ "$output" == *"Copy an existing user/*.nix profile"* ]]

  run "${JUST[@]}" _home-target ../escape aarch64-darwin darwin
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid profile name"* ]]
}

@test "system apply rejects a Home Manager profile" {
  run "${JUST[@]}" apply system vpplab
  [ "$status" -eq 2 ]
  [[ "$output" == *"profile applies only to Home Manager"* ]]
}

@test "public namespaces validate their subcommands" {
  run "${JUST[@]}" sync unknown
  [ "$status" -eq 2 ]
  [[ "$output" == *"Expected: just sync"* ]]

  run "${JUST[@]}" check unknown
  [ "$status" -eq 2 ]
  [[ "$output" == *"Expected: just check"* ]]

  run "${JUST[@]}" maintenance gc unknown
  [ "$status" -eq 2 ]
  [[ "$output" == *"maintenance gc"* ]]

  run "${JUST[@]}" image list ignored
  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: just image list"* ]]

  run "${JUST[@]}" image build iso unexpected-arch
  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: just image build"* ]]
}

@test "Fish completion is dynamic and repository scoped" {
  run rg -n "just-tonys-nix.fish" \
    "$REPO_ROOT/modules/shell/fish.hm.nix" "$REPO_ROOT/justfile"
  [ "$status" -eq 0 ]

  run rg -n "__tonys_nix_just_context|__tonys_nix_just_at|JUST_COMPLETE=fish|collect-user-profiles.nix" \
    "$REPO_ROOT/completions/just-tonys-nix.fish"
  [ "$status" -eq 0 ]

  run rg -n "/Users/vpplab/dev/tonys-nix" \
    "$REPO_ROOT/modules/shell/fish.hm.nix" "$REPO_ROOT/completions/just-tonys-nix.fish"
  [ "$status" -eq 1 ]

  run fish -c "complete -e -c just; source '$REPO_ROOT/completions/just-tonys-nix.fish'; complete -C 'just setup '"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'completions\tInstall only the Fish completion file'* ]]
  [[ "$output" == *$'home\tPrepare and apply Home Manager'* ]]

  run fish -c "complete -e -c just; source '$REPO_ROOT/completions/just-tonys-nix.fish'; complete -C 'just check '"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'core\tPrepare bootstrap runtime and run fast apply-gating checks'* ]]
}
