#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
}

@test "nix-darwin declares the current host Homebrew baseline" {
  run sed -n '1,160p' "$REPO_ROOT/hosts/tonys-mac.nix"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"just"'* ]]
  [[ "$output" == *'name = "tailscale"'* ]]
  [[ "$output" == *'"brave-browser"'* ]]
  [[ "$output" == *'"raycast"'* ]]
  [[ "$output" == *'"wezterm"'* ]]
  [[ "$output" == *'cleanup = "none"'* ]]
}

@test "brew sync applies the current nix-darwin host" {
  run just --justfile "$REPO_ROOT/justfile" --dry-run sync brew
  [ "$status" -eq 0 ]
  [[ "$output" == *"just apply system"* ]]

  run just --justfile "$REPO_ROOT/justfile" --dry-run _apply-system aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *"scutil --get LocalHostName"* ]]
  [[ "$output" == *'nix run .#darwin-rebuild'* ]]

  run just --justfile "$REPO_ROOT/justfile" --set OS_TYPE linux sync brew
  [ "$status" -ne 0 ]
  [[ "$output" == *"Homebrew sync requires macOS"* ]]
}

@test "brew sync no longer exposes remote Brewfile operations" {
  run just --justfile "$REPO_ROOT/justfile" --list
  [ "$status" -eq 0 ]
  [[ "$output" != *"_brew-export"* ]]
  [[ "$output" != *"_brew-import"* ]]
  [[ "$output" != *"_brew-check"* ]]
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
  [[ "$output" != *'raycast action="guide"'* ]]

  run rg -n "configurationExport|_raycast-(export|import|status)|open -a Raycast" \
    "$REPO_ROOT/recipes/sync.just"
  [ "$status" -eq 1 ]
}
