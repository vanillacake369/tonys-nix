#!/usr/bin/env bash
set -uo pipefail

usage() {
  echo "usage: run-observed.sh <stage> [attempt] -- <command> [args...]" >&2
  exit 2
}

[[ $# -ge 3 ]] || usage
stage=$1
shift
attempt=""
if [[ ${1:-} != -- ]]; then
  attempt=$1
  shift
fi
[[ ${1:-} == -- ]] || usage
shift
[[ $# -gt 0 ]] || usage

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
log_root=${OBSERVE_LOG_ROOT:-"$repo_root/.cache/just/errors"}
heartbeat_seconds=${OBSERVE_HEARTBEAT_SECONDS:-30}
show_activity=${OBSERVE_SHOW_ACTIVITY:-0}
activity_max_chars=${OBSERVE_ACTIVITY_MAX_CHARS:-160}
failure_detail=${OBSERVE_FAILURE_DETAIL:-1}
mkdir -p "$log_root"
tmp_log=$(mktemp "$log_root/.running.XXXXXX")
start_seconds=$SECONDS
child_pid=""
heartbeat_pid=""
start_line="[→] $stage"

elapsed() {
  local seconds=$((SECONDS - start_seconds))
  if (( seconds >= 60 )); then
    printf '%dm %02ds' "$((seconds / 60))" "$((seconds % 60))"
  else
    printf '%ds' "$seconds"
  fi
}

latest_activity() {
  tail -n 80 "$tmp_log" 2>/dev/null \
    | awk 'NF { line=$0 } END { print line }' \
    | sed $'s/\033\\[[0-9;?]*[ -\\/]*[@-~]//g' \
    | tr '\r\t' '  ' \
    | tr -d '\000-\010\013\014\016-\037\177' \
    | cut -c "1-${activity_max_chars}"
}

stop_heartbeat() {
  if [[ -n "$heartbeat_pid" ]]; then
    kill "$heartbeat_pid" 2>/dev/null || true
    wait "$heartbeat_pid" 2>/dev/null || true
    heartbeat_pid=""
  fi
}

# shellcheck disable=SC2329 # Invoked indirectly by the signal handler trap.
terminate_group() {
  local group_pid=$1
  local signal=$2
  local checks=0

  kill -s "$signal" -- "-$group_pid" 2>/dev/null || true
  while kill -0 -- "-$group_pid" 2>/dev/null && (( checks < 20 )); do
    sleep 0.05
    ((checks++))
  done
  if kill -0 -- "-$group_pid" 2>/dev/null; then
    kill -KILL -- "-$group_pid" 2>/dev/null || true
  fi
}

# shellcheck disable=SC2329 # Invoked by the signal traps below.
on_signal() {
  local status=$1
  local signal=$2
  trap - INT TERM
  if [[ -n "$child_pid" ]]; then
    terminate_group "$child_pid" "$signal"
    wait "$child_pid" 2>/dev/null || true
    child_pid=""
  fi
  stop_heartbeat
  rm -f "$tmp_log"
  echo "[!] Interrupted during $stage (exit $status, elapsed: $(elapsed))" >&2
  exit "$status"
}

trap 'on_signal 130 INT' INT
trap 'on_signal 143 TERM' TERM
trap 'stop_heartbeat; rm -f "$tmp_log"' EXIT

echo "$start_line"
# Monitor mode gives this background job its own process group, with $! as the
# group leader. Disable it immediately so job-control notices never reach the
# non-interactive console output.
set -m
"$@" >"$tmp_log" 2>&1 &
child_pid=$!
set +m

(
  heartbeat_sleep_pid=""
  previous_activity=""
  # shellcheck disable=SC2329 # Invoked by the subshell traps below.
  stop_heartbeat_sleep() {
    [[ -n "$heartbeat_sleep_pid" ]] && kill "$heartbeat_sleep_pid" 2>/dev/null || true
  }
  trap 'stop_heartbeat_sleep; exit 0' INT TERM EXIT
  while true; do
    sleep "$heartbeat_seconds" &
    heartbeat_sleep_pid=$!
    wait "$heartbeat_sleep_pid" || exit 0
    heartbeat_sleep_pid=""
    echo "[…] $stage still running (elapsed: $(elapsed))"
    if [[ "$show_activity" == 1 ]]; then
      activity=$(latest_activity)
      if [[ -n "$activity" && "$activity" != "$previous_activity" ]]; then
        echo "    latest: $activity"
        previous_activity=$activity
      fi
    fi
  done
) &
heartbeat_pid=$!

wait "$child_pid"
status=$?
child_pid=""
stop_heartbeat

if (( status == 0 )); then
  if [[ -n ${OBSERVE_RESULT_FILE:-} ]]; then
    cp "$tmp_log" "$OBSERVE_RESULT_FILE"
  fi
  rm -f "$tmp_log"
  echo "[✓] $stage (elapsed: $(elapsed))"
  exit 0
fi

if [[ "$failure_detail" == 1 ]]; then
  timestamp=$(date '+%Y%m%d-%H%M%S')
  safe_stage=$(printf '%s' "$stage" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')
  failed_log="$log_root/observed-${timestamp}-${safe_stage:-command}-$$.log"
  mv "$tmp_log" "$failed_log"
  failure_header="[✗] $stage failed
    exit: $status
    elapsed: $(elapsed)"
  [[ -n "$attempt" ]] && failure_header="$failure_header
    attempt: $attempt"
  failure_header="$failure_header
    log: $failed_log
    last output:"
  printf '%s\n' "$failure_header" >&2

  excerpt_file=$(mktemp "$log_root/.excerpt.XXXXXX")
  tail -n 40 "$failed_log" | sed 's/^/      /' >"$excerpt_file"
  fixed_bytes=$(
    { printf '%s\n' "$start_line"; printf '%s\n' "$failure_header"; } | wc -c | tr -d ' '
  )
  excerpt_budget=$((8192 - fixed_bytes))
  if (( excerpt_budget > 0 )); then
    tail -c "$excerpt_budget" "$excerpt_file" >&2
  fi
  rm -f "$excerpt_file"

  find "$log_root" -maxdepth 1 -type f -name 'observed-*.log' -print0 \
    | xargs -0 ls -1t 2>/dev/null \
    | awk 'NR > 10' \
    | while IFS= read -r old_log; do rm -f -- "$old_log"; done
else
  rm -f "$tmp_log"
  echo "[✗] $stage failed" >&2
  echo "    exit: $status" >&2
  echo "    elapsed: $(elapsed)" >&2
  [[ -n "$attempt" ]] && echo "    attempt: $attempt" >&2
fi

exit "$status"
