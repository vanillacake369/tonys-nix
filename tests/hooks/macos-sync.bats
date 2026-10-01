#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
}

@test "Brewfile contains the shared Mac baseline" {
  run sed -n '1,120p' "$REPO_ROOT/Brewfile"
  [ "$status" -eq 0 ]
  [[ "$output" == *'brew "just"'* ]]
  [[ "$output" == *'brew "tailscale"'* ]]
  [[ "$output" == *'cask "brave-browser"'* ]]
  [[ "$output" == *'cask "raycast"'* ]]
}

@test "brew import is additive and skips upgrades" {
  run just --justfile "$REPO_ROOT/justfile" --dry-run brew import
  [ "$status" -eq 0 ]
  [[ "$output" == *"_brew-import"* ]]

  run just --justfile "$REPO_ROOT/justfile" --dry-run _brew-import local
  [ "$status" -eq 0 ]
  [[ "$output" == *"brew bundle install"* ]]
  [[ "$output" == *"--no-upgrade"* ]]
  [[ "$output" != *"bundle cleanup"* ]]

  run just --justfile "$REPO_ROOT/justfile" --dry-run \
    _brew-import user@example-host
  [ "$status" -eq 0 ]
  [[ "$output" == *'target='*'user@example-host'* ]]
  [[ "$output" == *'tailscale ssh "$target"'* ]]
}

@test "Brew remote targets are arguments instead of host magic values" {
  run rg -n "tonys-mac-air|vpp-mac-pro|limjihoon@|/Users/limjihoon" \
    "$REPO_ROOT/justfile"
  [ "$status" -eq 1 ]

  run rg -n "RAYCAST_AIR_HOST|SOPS_AGE_AIR_HOST|SOPS_AGE_REMOTE_FILE" \
    "$REPO_ROOT/justfile"
  [ "$status" -eq 1 ]

  run just --justfile "$REPO_ROOT/justfile" _brew-check "-bad"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid Brew target"* ]]

  run just --justfile "$REPO_ROOT/justfile" _brew-import "bad target"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Invalid Brew target"* ]]
}

@test "Raycast commands only print the supported GUI workflow" {
  run just --justfile "$REPO_ROOT/justfile" raycast export
  [ "$status" -eq 0 ]
  [[ "$output" == *"Export Settings & Data"* ]]
  [[ "$output" == *"no supported headless CLI"* ]]

  run just --justfile "$REPO_ROOT/justfile" raycast import
  [ "$status" -eq 0 ]
  [[ "$output" == *"double-click the transferred .rayconfig file"* ]]
  [[ "$output" == *"Import merges data"* ]]

  run just --justfile "$REPO_ROOT/justfile" raycast status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Verify the imported configuration"* ]]
  [[ "$output" == *"no supported CLI"* ]]
}

@test "public sync commands expose domain subcommands" {
  run just --justfile "$REPO_ROOT/justfile" --list
  [ "$status" -eq 0 ]
  [[ "$output" == *'sync domain action="guide"'* ]]
  [[ "$output" != *"brew action"* ]]
  [[ "$output" != *'raycast action="guide"'* ]]

  run rg -n "configurationExport|_raycast-(export|import|status)|open -a Raycast" \
    "$REPO_ROOT/justfile"
  [ "$status" -eq 1 ]
}
