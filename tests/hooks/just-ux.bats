#!/usr/bin/env bats

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  JUST=(just --justfile "$REPO_ROOT/justfile")
  OBSERVER="$REPO_ROOT/scripts/run-observed.sh"
}

@test "observed commands report progress, elapsed time, and remove successful logs" {
  log_root="$BATS_TEST_TMPDIR/success-logs"
  run env OBSERVE_LOG_ROOT="$log_root" OBSERVE_HEARTBEAT_SECONDS=1 \
    bash "$OBSERVER" "Building fixture" -- bash -c 'sleep 2'
  [ "$status" -eq 0 ]
  [[ "$output" == *"[→] Building fixture"* ]]
  [[ "$output" == *"[…] Building fixture still running"* ]]
  [[ "$output" == *"[✓] Building fixture"* ]]
  [[ "$output" == *"elapsed:"* ]]
  [[ "$output" != *"[1]"* ]]
  [[ "$output" != *"Done"* ]]
  [ -z "$(find "$log_root" -type f 2>/dev/null)" ]
}

@test "observed commands can report sanitized bounded latest activity" {
  log_root="$BATS_TEST_TMPDIR/activity-logs"
  run env OBSERVE_LOG_ROOT="$log_root" OBSERVE_HEARTBEAT_SECONDS=1 \
    OBSERVE_SHOW_ACTIVITY=1 OBSERVE_ACTIVITY_MAX_CHARS=20 \
    bash "$OBSERVER" "Building fixture" -- bash -c \
    'printf "\033[31mderivation\033[0m\twith\rcontrol-and-a-long-suffix\n"; sleep 2'
  [ "$status" -eq 0 ]
  [[ "$output" == *"latest: derivation with cont"* ]]
  [[ "$output" != *$'\033'* ]]
  [[ "$output" != *$'\r'* ]]
  [[ "$output" != *$'\t'* ]]
  [ -z "$(find "$log_root" -type f 2>/dev/null)" ]
}

@test "observed command failures keep a bounded diagnostic and full log" {
  log_root="$BATS_TEST_TMPDIR/failure-logs"
  run env OBSERVE_LOG_ROOT="$log_root" \
    bash "$OBSERVER" "Failing fixture" "2/3" -- bash -c \
    'i=1; while [ "$i" -le 60 ]; do printf "line-%02d-%0250d\n" "$i" 0; i=$((i + 1)); done; exit 7'
  [ "$status" -eq 7 ]
  [[ "$output" == *"[✗] Failing fixture failed"* ]]
  [[ "$output" == *"exit: 7"* ]]
  [[ "$output" == *"attempt: 2/3"* ]]
  [[ "$output" == *"last output:"* ]]
  [ "$(printf '%s\n' "$output" | awk '/last output:/{seen=1; next} seen && /^      /{count++} END{print count+0}')" -le 40 ]
  [ "$(printf '%s' "$output" | wc -c | tr -d ' ')" -le 8192 ]
  log_file="$(find "$log_root" -type f | head -1)"
  [ -n "$log_file" ]
  [ "$(wc -l < "$log_file" | tr -d ' ')" -eq 60 ]
}

@test "observed command retains only the latest ten failed logs" {
  log_root="$BATS_TEST_TMPDIR/retained-logs"
  mkdir -p "$log_root"
  printf 'keep me\n' >"$log_root/unrelated.log"
  for i in $(seq 1 12); do
    env OBSERVE_LOG_ROOT="$log_root" bash "$OBSERVER" "failure-$i" -- bash -c 'exit 1' >/dev/null 2>&1 || true
  done
  [ "$(find "$log_root" -type f -name 'observed-*.log' | wc -l | tr -d ' ')" -eq 10 ]
  [ "$(cat "$log_root/unrelated.log")" = "keep me" ]
}

@test "observed command reports termination with the signal status" {
  log_root="$BATS_TEST_TMPDIR/signal-logs"
  descendant_pid_file="$BATS_TEST_TMPDIR/descendant.pid"
  started=$SECONDS
  run bash -c '
    OBSERVE_LOG_ROOT="$1" bash "$2" "Interrupted fixture" -- \
      bash -c '\''sleep 20 & echo $! >"$1"; wait'\'' _ "$3" &
    pid=$!
    while [ ! -s "$3" ]; do sleep 0.05; done
    kill -TERM "$pid"
    wait "$pid"
  ' _ "$log_root" "$OBSERVER" "$descendant_pid_file"
  duration=$((SECONDS - started))
  [ "$status" -eq 143 ]
  [ "$duration" -lt 5 ]
  [[ "$output" == *"Interrupted during Interrupted fixture (exit 143"* ]]
  descendant_pid="$(cat "$descendant_pid_file")"
  ! kill -0 "$descendant_pid" 2>/dev/null
  [ -z "$(find "$log_root" -type f 2>/dev/null)" ]

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
  [[ "$output" == *"just _bootstrap-core"* ]]
  [[ "$output" == *"just lint"* ]]
  [[ "$output" == *'"Running guard tests" -- just _test-guard'* ]]

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
  [[ "$output" == *'run-observed.sh'* ]]
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
  [[ "$output" == *'"Activating Home Manager"'* ]]
  [[ "$output" == *'OBSERVE_HEARTBEAT_SECONDS="10"'* ]]
  [[ "$output" == *'OBSERVE_SHOW_ACTIVITY=1'* ]]
  [[ "$output" == *'OBSERVE_ACTIVITY_MAX_CHARS='* ]]

  run "${JUST[@]}" --dry-run _reclaim-matching-home-files hm-vpplab-aarch64-darwin
  [ "$status" -eq 0 ]
  [[ "$output" == *"home-files"* ]]
  [[ "$output" == *'"Building Home Manager generation"'* ]]
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
