#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  JUST=(just --justfile "$REPO_ROOT/justfile")
}

@test "bare just stops before apply when core checks fail" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/just" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
[[ "$*" != "_bootstrap-core" && "$*" != "check core" ]] || exit 42
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/just"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" "$(command -v just)" --justfile "$REPO_ROOT/justfile"
  [ "$status" -eq 42 ]
  [[ "$output" != *"apply all"* ]]
}

@test "home apply refuses to activate after an invalid generation build" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/nix" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' /tmp/invalid-generation
exit "${BUILD_STATUS:-0}"
EOF
  cat > "$BATS_TEST_TMPDIR/bin/home-manager" <<'EOF'
#!/usr/bin/env bash
echo "unexpected activation"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/"*
  for build_status in 0 42; do
    run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" BUILD_STATUS="$build_status" \
      "${JUST[@]}" _apply-home hm-vpplab-aarch64-darwin
    [ "$status" -ne 0 ]
    [[ "$output" != *"unexpected activation"* ]]
  done
}

@test "home apply retries before using the fallback cache" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/just" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == _reclaim-matching-home-files ]]
EOF
  cat > "$BATS_TEST_TMPDIR/bin/home-manager" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *substituters*) echo fallback; exit "${FALLBACK_STATUS:-0}" ;;
  *) echo primary; exit "${PRIMARY_STATUS:-0}" ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/"*

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" "$(command -v just)" \
    --justfile "$REPO_ROOT/justfile" _apply-home hm-vpplab-aarch64-darwin
  [ "$status" -eq 0 ]
  [ "$(printf '%s\n' "$output" | grep -c '^primary$')" -eq 1 ]
  [[ "$output" != *fallback* ]]

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" PRIMARY_STATUS=1 FALLBACK_STATUS=42 \
    "$(command -v just)" --justfile "$REPO_ROOT/justfile" _apply-home hm-vpplab-aarch64-darwin
  [ "$status" -eq 42 ]
  [ "$(printf '%s\n' "$output" | grep -c '^primary$')" -eq 3 ]
  [ "$(printf '%s\n' "$output" | grep -c '^fallback$')" -eq 1 ]
}

@test "bare just runs core checks before applying all" {
  run "${JUST[@]}" --show default
  [ "$status" -eq 0 ]
  [[ "$output" == *'just _preflight-default'* ]]
  [[ "$output" == *'just check core'* ]]
  [[ "$output" == *'just apply all'* ]]

  run "${JUST[@]}" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"just _preflight-default"* ]]
  [[ "$output" == *"just check core"* ]]
  [[ "$output" != *"mktemp"* ]]
  [[ "$output" != *".log"* ]]
  preflight_line="$(printf '%s\n' "$output" | grep -n 'just _preflight-default' | head -1 | cut -d: -f1)"
  check_line="$(printf '%s\n' "$output" | grep -n 'just check core' | head -1 | cut -d: -f1)"
  apply_line="$(printf '%s\n' "$output" | grep -n 'just apply all' | head -1 | cut -d: -f1)"
  [ "$preflight_line" -lt "$check_line" ]
  [ "$check_line" -lt "$apply_line" ]

  run "${JUST[@]}" --dry-run _preflight-default
  [ "$status" -eq 0 ]
  [[ "$output" == *'just _home-profile-check "$(id -un)"'* ]]
  [[ "$output" == *'just _darwin-config'* ]]
}

@test "bare just rejects an unknown login before bootstrap" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/id" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "-un" ]]; then echo missing-user; else exec /usr/bin/id "$@"; fi
EOF
  cat > "$BATS_TEST_TMPDIR/bin/just" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == _bootstrap-core ]]; then echo "unexpected bootstrap"; exit 99; fi
if [[ "$1" == --justfile ]]; then exec "$REAL_JUST" "$@"; fi
exec "$REAL_JUST" --justfile "$REPO_ROOT/justfile" "$@"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/"*

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" REAL_JUST="$(command -v just)" \
    REPO_ROOT="$REPO_ROOT" "${JUST[@]}"
  [ "$status" -eq 2 ]
  [[ "$output" == *"user/missing-user.nix"* ]]
  [[ "$output" != *"unexpected bootstrap"* ]]
}

@test "NixOS hardware preflight fails before bootstrap and never generates a configuration" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/just" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == _bootstrap-core ]]; then echo "unexpected bootstrap"; exit 99; fi
if [[ "$1" == --justfile ]]; then exec "$REAL_JUST" "$@"; fi
exec "$REAL_JUST" --justfile "$REPO_ROOT/justfile" --set OS_TYPE nixos "$@"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/just"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" REAL_JUST="$(command -v just)" \
    REPO_ROOT="$REPO_ROOT" "${JUST[@]}" --set OS_TYPE nixos _nixos-hardware-check \
    "$BATS_TEST_TMPDIR/missing.nix"
  [ "$status" -eq 2 ]
  [[ "$output" == *"nixos-generate-config"* ]]
  [[ "$output" != *"unexpected bootstrap"* ]]

  printf '%s\n' '{}' > "$BATS_TEST_TMPDIR/hardware.nix"
  run "${JUST[@]}" --set OS_TYPE nixos _nixos-hardware-check \
    "$BATS_TEST_TMPDIR/hardware.nix"
  [ "$status" -eq 0 ]

  run "${JUST[@]}" --dry-run _preflight-default
  [[ "$output" == *'_nixos-hardware-check'* ]]
  run "${JUST[@]}" --dry-run _apply-system x86_64-linux
  [[ "$output" == *'_nixos-hardware-check'* ]]
  [[ "$output" != *'sudo nixos-generate-config'* ]]
}

@test "core checks bootstrap runtime before lint and guard contracts" {
  run "${JUST[@]}" --dry-run check core
  [ "$status" -eq 0 ]
  [[ "$output" == *"just _bootstrap-core"* ]]
  [[ "$output" == *"just lint"* ]]
  [[ "$output" == *"just _test-guard"* ]]

  run "${JUST[@]}" --dry-run _bootstrap-core
  [ "$status" -eq 0 ]
  [[ "$output" == *"just install-nix"* ]]
  [[ "$output" == *"just system-link-nix-conf"* ]]
  [[ "$output" == *"just install-home-manager"* ]]
}

@test "core tools fall back to nix on a plain environment" {
  run "${JUST[@]}" --dry-run lint
  [ "$status" -eq 0 ]
  [[ "$output" == *'nix run "nixpkgs#${tool}" -- "$@"'* ]]

  run "${JUST[@]}" --dry-run _test-guard
  [ "$status" -eq 0 ]
  [[ "$output" == *"nix run nixpkgs#jq --"* ]]
}

@test "apply success path uses concise console output" {
  run "${JUST[@]}" --dry-run apply all
  [ "$status" -eq 0 ]
  [[ "$output" == *'[→] Home Manager: $target'* ]]
  [[ "$output" == *'just _apply-validate'* ]]
  target_line="$(printf '%s\n' "$output" | grep -n 'target="$(just _home-target' | head -1 | cut -d: -f1)"
  system_line="$(printf '%s\n' "$output" | grep -n 'just _apply-system' | head -1 | cut -d: -f1)"
  [ "$target_line" -lt "$system_line" ]
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

@test "apply all rejects a missing profile before system activation" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/just" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == _apply-system ]]; then echo "unexpected system activation"; exit 99; fi
if [[ "$1" == --justfile ]]; then exec "$REAL_JUST" "$@"; fi
exec "$REAL_JUST" --justfile "$REPO_ROOT/justfile" "$@"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/just"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" REAL_JUST="$(command -v just)" \
    REPO_ROOT="$REPO_ROOT" "${JUST[@]}" apply all missing-user
  [ "$status" -eq 2 ]
  [[ "$output" == *"user/missing-user.nix"* ]]
  [[ "$output" != *"unexpected system activation"* ]]
}

@test "home apply reclaims matching managed files before backup overwrite" {
  run "${JUST[@]}" --dry-run _apply-home hm-vpplab-aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *'just _reclaim-matching-home-files "$flake_target"'* ]]
  [[ "$output" == *'"${hm_cmd[@]}" switch'* ]]

  run "${JUST[@]}" --dry-run _reclaim-matching-home-files hm-vpplab-aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *"home-files"* ]]
  [[ "$output" == *"Building Home Manager generation"* ]]
  [[ "$output" == *'nix build --print-build-logs --print-out-paths'* ]]
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
    "$REPO_ROOT/modules/shell/fish.hm.nix" "$REPO_ROOT/recipes/setup.just"
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

  run fish -c "complete -e -c just; source '$REPO_ROOT/completions/just-tonys-nix.fish'; complete -C 'just sync brew '"
  [ "$status" -eq 0 ]
  [[ "$output" == "sync" ]]
  [[ "$output" != *'Brewfile'* ]]

  run fish -c "complete -e -c just; source '$REPO_ROOT/completions/just-tonys-nix.fish'; complete -C 'just check '"
  [ "$status" -eq 0 ]
  [[ "$output" == *$'core\tPrepare bootstrap runtime and run fast apply-gating checks'* ]]
}
