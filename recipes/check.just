# Run quality gates. Targets: all, core, flake, hooks, lint.
check target="all":
    #!/usr/bin/env bash
    set -euo pipefail
    case {{ quote(target) }} in
      all) just lint && just test ;;
      core)
        just _bootstrap-core
        just lint
        just _test-guard
        ;;
      flake) just _test-flake ;;
      hooks) just test-hooks ;;
      lint) just lint ;;
      *) echo "[x] Expected: just check {all|core|flake|hooks|lint}" >&2; exit 2 ;;
    esac

# Run guard tests (nix eval) + shell hook tests (bats).
[private]
test: test-hooks
    just _test-flake

# Guard 빌드는 테스트 요약을 생성한다.
# 요약의 총계와 통과 개수를 비교해 recipe의 종료 상태를 결정한다.
[private]
_test-guard:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v jq >/dev/null 2>&1; then
      jq_cmd=(jq)
    else
      jq_cmd=(nix run nixpkgs#jq --)
    fi

    out=$(nix build --print-out-paths ".#checks.{{ SYSTEM_ARCH }}.guard-tests" --no-link)
    "${jq_cmd[@]}" -r '"[→] guard-tests \(.passed)/\(.total)"' "$out"
    "${jq_cmd[@]}" -e '(.total | type == "number") and .passed == .total' "$out" >/dev/null

# Build every flake check for the current system.
[private]
_test-flake: _test-guard
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v jq >/dev/null 2>&1; then
      jq_cmd=(jq)
    else
      jq_cmd=(nix run nixpkgs#jq --)
    fi

    nix eval .#checks.{{ SYSTEM_ARCH }} --apply builtins.attrNames --json \
      | "${jq_cmd[@]}" -r '.[] | select(. != "guard-tests")' \
      | while IFS= read -r check; do
          echo "[→] Flake check: $check"
          nix build ".#checks.{{ SYSTEM_ARCH }}.$check" --no-link
        done

# Run shell hook tests (bats). Falls back to `nix run` when bats is unbuilt.
[private]
test-hooks:
    #!/usr/bin/env bash
    hook_tests="$(find tests/hooks -maxdepth 1 -type f -name '*.bats' | sort)"
    if command -v bats &>/dev/null; then
      bats $hook_tests
    else
      nix run nixpkgs#bats -- $hook_tests
    fi

# Run linters and the flake's configured formatter check.
[private]
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    run_tool() {
      local tool="$1"
      shift
      echo "[→] $tool"
      if command -v "$tool" >/dev/null 2>&1; then
        "$tool" "$@"
      else
        nix run "nixpkgs#${tool}" -- "$@"
      fi
    }

    run_tool deadnix --fail .
    run_tool statix check .
    echo "[→] formatting"
    nix build ".#checks.{{ SYSTEM_ARCH }}.formatting" --no-link
