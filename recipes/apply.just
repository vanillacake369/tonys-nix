HOSTNAME := `hostname`
APPLY_RETRY_THRESHOLD := "3"
APPLY_FALLBACK_SUBSTITUTERS := "https://cache.nixos.org"

# Apply the current login user's profile. Scopes: all, home, system.
apply scope="all" profile="":
    #!/usr/bin/env bash
    set -euo pipefail
    scope={{ quote(scope) }}
    profile={{ quote(profile) }}
    system={{ quote(SYSTEM_ARCH) }}

    case "$scope" in
      x86_64-linux|aarch64-linux|aarch64-darwin)
        echo "[!] Deprecated: use 'just apply all [profile]' instead of 'just apply $scope'" >&2
        system="$scope"
        scope=all
        ;;
    esac
    case "$scope" in
      all|home|system) ;;
      *) echo "[x] Expected: just apply {all|home|system} [profile]" >&2; exit 2 ;;
    esac
    if [[ "$scope" == system && -n "$profile" ]]; then
      echo "[x] A profile applies only to Home Manager; use 'just apply system'" >&2
      exit 2
    fi

    just _apply-validate "$system"
    if [[ "$scope" == all || "$scope" == system ]]; then
      just _apply-system "$system"
    fi
    if [[ "$scope" == all || "$scope" == home ]]; then
      [[ -n "$profile" ]] || profile="$(id -un)"
      target="$(just _home-target "$profile" "$system" {{ quote(OS_TYPE) }})"
      echo "[→] Home Manager: $target"
      just _apply-home "$target"
    fi

# Validate platform and target before applying any configuration.
[private]
_apply-validate target:
    #!/usr/bin/env bash
    case "{{ OS_TYPE }}" in
      nixos|wsl|darwin|linux)
    ;;
      *)
    echo "[✗] Unsupported platform: {{ OS_TYPE }}"
    exit 1
    ;;
    esac

    case "{{ target }}" in
      x86_64-linux|aarch64-linux|aarch64-darwin)
    ;;
      unsupported)
    echo "[✗] Unsupported system architecture"
    exit 1
    ;;
      *)
    echo "[!] Non-standard target requested: {{ target }}"
    ;;
    esac

# Apply system-level configuration for hosts that require it.
[private]
_apply-system target:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ OS_TYPE }}" == "darwin" ]]; then
      host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
      if [[ ! "$host" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "[x] Invalid macOS host name: $host" >&2
        exit 2
      fi
      if command -v jq >/dev/null 2>&1; then
        jq_cmd=(jq)
      else
        jq_cmd=(nix run nixpkgs#jq --)
      fi
      configurations="$(nix eval --json --no-update-lock-file .#darwinConfigurations --apply builtins.attrNames)"
      requested="${DARWIN_CONFIG:-}"
      if [[ -n "$requested" ]]; then
        host="$("${jq_cmd[@]}" -r --arg name "$requested" 'if index($name) then $name else empty end' <<< "$configurations")"
      else
        host="$("${jq_cmd[@]}" -r --arg name "$host" 'if index($name) then $name elif length == 1 then .[0] else empty end' <<< "$configurations")"
      fi
      if [[ -z "$host" ]]; then
        echo "[x] Cannot select a nix-darwin configuration. Available: $("${jq_cmd[@]}" -r 'join(", ")' <<< "$configurations")" >&2
        echo "    Run with DARWIN_CONFIG=<name> just apply system" >&2
        exit 2
      fi
      echo "[→] nix-darwin configuration: $host"
      login_user="$(id -un)"
      if command -v darwin-rebuild >/dev/null 2>&1; then
        sudo -H env "TONYS_NIX_DARWIN_USER=$login_user" "$(command -v darwin-rebuild)" switch --flake ".#$host" --impure
      else
        sudo -H env "TONYS_NIX_DARWIN_USER=$login_user" "$(command -v nix)" run .#darwin-rebuild -- switch --flake ".#$host" --impure
      fi
      exit 0
    fi
    if [[ "{{ OS_TYPE }}" != "nixos" ]]; then
      exit 0
    fi

    echo "[!] Checking NixOS hardware configuration"
    if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
      echo "[!] Generating /etc/nixos/hardware-configuration.nix"
      sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration.nix
      echo "[✓] Generated /etc/nixos/hardware-configuration.nix"
    fi

    echo "[!] Applying NixOS system configuration"
    retry_threshold="{{ APPLY_RETRY_THRESHOLD }}"
    attempt=1
    while (( attempt <= retry_threshold )); do
      echo "[→] Attempt ${attempt}/${retry_threshold}: sudo nixos-rebuild switch --flake .#{{ HOSTNAME }} --impure"
      if sudo nixos-rebuild switch --flake .#"{{ HOSTNAME }}" --impure; then
        exit 0
      fi
      echo "[!] NixOS system apply failed on attempt ${attempt}/${retry_threshold}"
      (( attempt++ ))
    done

    echo "[!] Falling back to substituters={{ APPLY_FALLBACK_SUBSTITUTERS }}"
    sudo nixos-rebuild switch \
      --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}" \
      --flake .#"{{ HOSTNAME }}" \
      --impure

# Resolve a login/profile name to an existing named Home Manager output.
# NOTE:
#   shell 로그인 사용자는 Just runtime에서만 판별하고 flake에 impure 값으로
#   주입하지 않는다. user/<profile>.nix가 선언한 named output을 선택하는
#   경계를 지켜야 동일한 flake가 로컬·CI에서 같은 결과로 평가된다.
[private]
_home-target profile system os:
    #!/usr/bin/env bash
    set -euo pipefail
    profile={{ quote(profile) }}
    system={{ quote(system) }}
    os={{ quote(os) }}
    profile_file="{{ justfile_directory() }}/user/${profile}.nix"

    if [[ ! "$profile" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
      echo "[x] Invalid profile name: $profile" >&2
      exit 2
    fi
    if [[ ! -f "$profile_file" ]]; then
      echo "[x] Cannot find a Nix profile for login user '$profile'." >&2
      echo "    Expected: user/${profile}.nix" >&2
      echo "    Copy an existing user/*.nix profile, update its identity fields, and retry." >&2
      exit 2
    fi
    if ! git -C "{{ justfile_directory() }}" ls-files --error-unmatch -- "user/${profile}.nix" >/dev/null 2>&1; then
      echo "[x] user/${profile}.nix exists but is not visible to the Git-backed flake." >&2
      echo "    Track it first: git add user/${profile}.nix" >&2
      exit 2
    fi

    case "$os" in
      nixos) target="hm-${profile}-nixos-${system}" ;;
      wsl) target="hm-${profile}-wsl-${system}" ;;
      darwin|linux) target="hm-${profile}-${system}" ;;
      *) echo "[x] Unsupported platform for Home Manager apply: $os" >&2; exit 2 ;;
    esac

    if command -v jq >/dev/null 2>&1; then
      jq_cmd=(jq)
    else
      jq_cmd=(nix run nixpkgs#jq --)
    fi

    if ! nix eval --json .#homeConfigurations --apply builtins.attrNames 2>/dev/null \
      | "${jq_cmd[@]}" -e --arg target "$target" 'index($target) != null' >/dev/null; then
      echo "[x] Flake output not found: homeConfigurations.$target" >&2
      echo "    Ensure user/${profile}.nix declares username = \"${profile}\"." >&2
      exit 2
    fi
    printf '%s\n' "$target"

# Apply an already-resolved Home Manager target.
[private]
_apply-home flake_target:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v home-manager >/dev/null 2>&1; then
      hm_cmd=(home-manager)
      hm_fallback_cmd=(home-manager switch --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}")
    else
      echo "[!] Bootstrapping Home Manager via flake"
      hm_cmd=(nix run home-manager/master --)
      hm_fallback_cmd=(nix --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}" run home-manager/master -- switch --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}")
    fi

    flake_target={{ quote(flake_target) }}

    just _reclaim-matching-home-files "$flake_target"

    retry_threshold="{{ APPLY_RETRY_THRESHOLD }}"
    attempt=1
    while (( attempt <= retry_threshold )); do
      echo "[→] Activating Home Manager (${attempt}/${retry_threshold})"
      if "${hm_cmd[@]}" switch --flake ".#${flake_target}" -b back; then
        exit 0
      fi
      (( attempt++ ))
    done

    echo "[!] Falling back to substituters={{ APPLY_FALLBACK_SUBSTITUTERS }}"
    "${hm_fallback_cmd[@]}" --flake ".#${flake_target}" -b back

# 새 세대와 내용이 같은 일반 파일은 적용 전에 회수한다.
# 빌드와 출력 경로 검증이 끝난 뒤에만 홈 디렉터리를 변경한다.
[private]
_reclaim-matching-home-files flake_target:
    #!/usr/bin/env bash
    set -euo pipefail
    flake_target={{ quote(flake_target) }}

    echo "[→] Building Home Manager generation"
    generation=$(nix build --print-build-logs --print-out-paths \
      ".#homeConfigurations.${flake_target}.activationPackage" --no-link)
    if [[ ! "$generation" =~ ^/nix/store/[^/[:space:]]+$ || ! -d "$generation/home-files" ]]; then
      echo "[✗] Invalid Home Manager generation: $generation" >&2
      exit 1
    fi
    home_files="$generation/home-files"

    reclaimed=0
    while IFS= read -r -d '' managed; do
      rel="${managed#${home_files}/}"
      target="$HOME/$rel"
      if [[ -f "$target" && ! -L "$target" ]] && cmp -s "$managed" "$target"; then
        rm -f "$target"
        ((++reclaimed))
      fi
    done < <(find "$home_files" \( -type f -o -type l \) -print0)

    if (( reclaimed > 0 )); then
      echo "[✓] Reclaimed matching Home Manager files: $reclaimed"
    fi
