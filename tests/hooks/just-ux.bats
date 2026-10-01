#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  JUST=(just --justfile "$REPO_ROOT/justfile")
}

@test "bare just checks everything before applying all" {
  run "${JUST[@]}" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"just check all"* ]]
  [[ "$output" == *"just apply all"* ]]
  check_line="$(printf '%s\n' "$output" | grep -n 'just check all' | head -1 | cut -d: -f1)"
  apply_line="$(printf '%s\n' "$output" | grep -n 'just apply all' | head -1 | cut -d: -f1)"
  [ "$check_line" -lt "$apply_line" ]
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

  run fish -c "source '$REPO_ROOT/completions/just-tonys-nix.fish'; complete -C 'just setup '"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'completions\tInstall only the Fish completion file'* ]]
  [[ "$output" == *$'home\tPrepare and apply Home Manager'* ]]
}
