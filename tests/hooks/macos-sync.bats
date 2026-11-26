#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
}

@test "Darwin host selection uses an exact host name or explicit config" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/scutil" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$FAKE_HOST"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/scutil"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    FAKE_HOST=tonys-mac just --justfile "$REPO_ROOT/justfile" _darwin-config
  [ "$status" -eq 0 ]
  [ "$output" = tonys-mac ]

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    FAKE_HOST=work-mac DARWIN_CONFIG=tonys-mac \
    just --justfile "$REPO_ROOT/justfile" _darwin-config
  [ "$status" -eq 0 ]
  [[ "$output" == *"Bound macOS host work-mac to tonys-mac"* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/config/tonys-nix/hosts/work-mac/config-name")" = tonys-mac ]

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    FAKE_HOST=work-mac just --justfile "$REPO_ROOT/justfile" _darwin-config
  [ "$status" -eq 0 ]
  [ "$output" = tonys-mac ]
}

@test "Darwin host selection refuses an unbound or stale host" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/scutil" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$FAKE_HOST"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/scutil"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    FAKE_HOST=work-mac just --justfile "$REPO_ROOT/justfile" _darwin-config
  [ "$status" -eq 2 ]
  [[ "$output" == *"DARWIN_CONFIG=tonys-mac"* ]]

  binding="$BATS_TEST_TMPDIR/config/tonys-nix/hosts/work-mac/config-name"
  mkdir -p "$(dirname "$binding")"
  printf '%s\n' unknown > "$binding"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    FAKE_HOST=work-mac just --justfile "$REPO_ROOT/justfile" _darwin-config
  [ "$status" -eq 2 ]
  [[ "$output" == *"Unknown nix-darwin configuration"* ]]

  printf '%s\n' tonys-mac > "$binding"
  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    FAKE_HOST=work-mac just --justfile "$REPO_ROOT/justfile" _darwin-config
  [ "$status" -eq 0 ]
  [ "$output" = tonys-mac ]
}

@test "Darwin plan can select an explicit config without persisting a binding" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/scutil" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' work-mac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/scutil"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    DARWIN_CONFIG=tonys-mac just --justfile "$REPO_ROOT/justfile" _darwin-config plan
  [ "$status" -eq 0 ]
  [ "$output" = tonys-mac ]
  [ ! -e "$BATS_TEST_TMPDIR/config/tonys-nix/hosts/work-mac/config-name" ]

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    just --justfile "$REPO_ROOT/justfile" _darwin-config plan
  [ "$status" -eq 2 ]
  [[ "$output" == *"DARWIN_CONFIG=tonys-mac just plan"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/config/tonys-nix/hosts/work-mac/config-name" ]
}

@test "bare just stops before bootstrap on an unbound Darwin host" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/scutil" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' unbound-mac
EOF
  cat > "$BATS_TEST_TMPDIR/bin/just" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == _bootstrap-core ]]; then echo "unexpected bootstrap"; exit 99; fi
if [[ "$1" == --justfile ]]; then exec "$REAL_JUST" "$@"; fi
exec "$REAL_JUST" --justfile "$REPO_ROOT/justfile" "$@"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/"*

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    REAL_JUST="$(command -v just)" REPO_ROOT="$REPO_ROOT" \
    just --justfile "$REPO_ROOT/justfile"
  [ "$status" -eq 2 ]
  [[ "$output" == *"No nix-darwin configuration bound"* ]]
  [[ "$output" != *"unexpected bootstrap"* ]]
}

@test "system apply passes the host-local module only to nix-darwin" {
  mkdir "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/scutil" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' work-mac
EOF
  cat > "$BATS_TEST_TMPDIR/bin/nix" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' '["tonys-mac"]'
EOF
  cat > "$BATS_TEST_TMPDIR/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*"
EOF
  cat > "$BATS_TEST_TMPDIR/bin/darwin-rebuild" <<'EOF'
#!/usr/bin/env bash
echo "unexpected activation"
exit 99
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/"*

  local_dir="$BATS_TEST_TMPDIR/config/tonys-nix/hosts/work-mac"
  mkdir -p "$local_dir"
  printf '%s\n' tonys-mac > "$local_dir/config-name"
  printf '%s\n' '{}' > "$local_dir/darwin.nix"

  run env PATH="$BATS_TEST_TMPDIR/bin:$PATH" XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config" \
    just --justfile "$REPO_ROOT/justfile" --set OS_TYPE darwin _apply-system aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *"TONYS_NIX_DARWIN_LOCAL_CONFIG=tonys-mac"* ]]
  [[ "$output" == *"TONYS_NIX_DARWIN_LOCAL_MODULE=$local_dir/darwin.nix"* ]]
  [[ "$output" != *"unexpected activation"* ]]
}

@test "nix-darwin declares the current host Homebrew baseline" {
  run sed -n '1,160p' "$REPO_ROOT/nodes/tonys-mac.darwin.nix"
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
  [[ "$output" == *'just _darwin-config'* ]]
  [[ "$output" == *"scutil --get LocalHostName"* ]]
  [[ "$output" == *'darwinConfigurations --apply builtins.attrNames'* ]]
  [[ "$output" == *'TONYS_NIX_DARWIN_USER=$login_user'* ]]
  [[ "$output" == *'TONYS_NIX_DARWIN_LOCAL_MODULE=$local_module'* ]]
  [[ "$output" == *'"$(command -v darwin-rebuild)" switch'* ]]
  [[ "$output" == *'--impure'* ]]
  [[ "$output" == *'run .#darwin-rebuild'* ]]

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
