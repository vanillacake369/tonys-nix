HOSTNAME := `hostname`
APPLY_RETRY_THRESHOLD := "3"
APPLY_FALLBACK_SUBSTITUTERS := "https://cache.nixos.org"

# Reject unsupported platforms and missing login profiles before bootstrap.
[private]
_preflight-default:
    #!/usr/bin/env bash
    set -euo pipefail
    just _apply-validate "{{ SYSTEM_ARCH }}"
    just _home-profile-check "$(id -un)"
    if [[ "{{ OS_TYPE }}" == darwin ]]; then
      just _darwin-config >/dev/null
    elif [[ "{{ OS_TYPE }}" == nixos ]]; then
      just _nixos-hardware-check
    fi

# A real NixOS machine must provide its own hardware scan before any setup.
[private]
_nixos-hardware-check path="/etc/nixos/hardware-configuration.nix":
    #!/usr/bin/env bash
    set -euo pipefail
    hardware={{ quote(path) }}
    if [[ ! -f "$hardware" || ! -r "$hardware" ]]; then
      echo "[x] Missing readable NixOS hardware configuration: $hardware" >&2
      echo "    On this machine, run: sudo nixos-generate-config --show-hardware-config | sudo tee /etc/nixos/hardware-configuration.nix >/dev/null" >&2
      echo "    Review /etc/nixos/hardware-configuration.nix before retrying." >&2
      exit 2
    fi

# Bind a macOS LocalHostName to a declared nix-darwin configuration.
# An explicit DARWIN_CONFIG confirms a new or changed binding. An exact name
# needs no binding; a single unmatched candidate prompts once on a terminal.
[private]
_darwin-config mode="apply":
    #!/usr/bin/env bash
    set -euo pipefail
    mode={{ quote(mode) }}
    case "$mode" in
      apply|plan) ;;
      *) echo "[x] Expected Darwin config mode: apply or plan" >&2; exit 2 ;;
    esac
    local_host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
    if [[ ! "$local_host" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      echo "[x] Invalid macOS host name: $local_host" >&2
      exit 2
    fi

    repo="{{ justfile_directory() }}"
    config_base="${XDG_CONFIG_HOME:-$HOME/.config}"
    if [[ "$config_base" != /* ]]; then
      echo "[x] XDG_CONFIG_HOME must be an absolute path" >&2
      exit 2
    fi
    local_dir="$config_base/tonys-nix/hosts/$local_host"
    binding="$local_dir/config-name"
    selected="${DARWIN_CONFIG:-}"
    persist=false

    if [[ -n "$selected" ]]; then
      if [[ "$mode" == apply ]]; then
        persist=true
      fi
    elif [[ -f "$binding" ]]; then
      selected="$(cat "$binding")"
    elif [[ -f "$repo/hosts/$local_host.nix" ]]; then
      selected="$local_host"
    else
      candidates=()
      while IFS= read -r path; do
        candidates+=("${path#hosts/}")
      done < <(git -C "$repo" ls-files 'hosts/*.nix')
      if (( ${#candidates[@]} == 1 )); then
        selected="${candidates[0]%.nix}"
        if [[ "$mode" == plan ]]; then
          echo "[x] No nix-darwin configuration bound to macOS host '$local_host'." >&2
          echo "    Preview with: DARWIN_CONFIG=$selected just plan" >&2
          exit 2
        fi
        if [[ ! -t 0 ]]; then
          echo "[x] No nix-darwin configuration bound to macOS host '$local_host'." >&2
          echo "    Bind it once: DARWIN_CONFIG=$selected just" >&2
          exit 2
        fi
        printf '[?] Bind macOS host %s to nix-darwin configuration %s? [y/N] ' "$local_host" "$selected" >&2
        answer=""
        read -r answer </dev/tty || true
        if [[ "$answer" != y && "$answer" != Y && "$answer" != yes && "$answer" != YES ]]; then
          echo "[x] Host binding was not confirmed" >&2
          exit 2
        fi
        persist=true
      else
        echo "[x] No nix-darwin configuration bound to macOS host '$local_host'." >&2
        if (( ${#candidates[@]} > 0 )); then
          printf '    Available: %s\n' "${candidates[*]%.nix}" >&2
        fi
        echo "    Select one once with DARWIN_CONFIG=<name> just" >&2
        exit 2
      fi
    fi

    if [[ ! "$selected" =~ ^[a-zA-Z0-9_-]+$ ]] \
      || [[ ! -f "$repo/hosts/$selected.nix" ]] \
      || ! git -C "$repo" ls-files --error-unmatch -- "hosts/$selected.nix" >/dev/null 2>&1; then
      echo "[x] Unknown nix-darwin configuration: $selected" >&2
      exit 2
    fi

    if [[ "$persist" == true && "$selected" != "$local_host" ]]; then
      mkdir -p "$local_dir"
      chmod 700 "$local_dir"
      temporary="$(mktemp "$local_dir/.config-name.XXXXXX")"
      trap 'rm -f "$temporary"' EXIT
      printf '%s\n' "$selected" > "$temporary"
      chmod 600 "$temporary"
      mv -f "$temporary" "$binding"
      echo "[✓] Bound macOS host $local_host to $selected in $binding" >&2
    fi
    printf '%s\n' "$selected"

# Preview selected output builds without activating or changing host binding.
plan scope="all" profile="":
    #!/usr/bin/env bash
    set -euo pipefail
    scope={{ quote(scope) }}
    profile={{ quote(profile) }}
    system={{ quote(SYSTEM_ARCH) }}
    os={{ quote(OS_TYPE) }}

    case "$scope" in
      all|home|system) ;;
      *) echo "[x] Expected: just plan {all|home|system} [profile]" >&2; exit 2 ;;
    esac
    if [[ "$scope" == system && -n "$profile" ]]; then
      echo "[x] A profile applies only to Home Manager; use 'just plan system'" >&2
      exit 2
    fi
    just _apply-validate "$system"
    if ! command -v nix >/dev/null 2>&1; then
      echo "[x] Nix is required for plan. Install it first with 'just setup nix'." >&2
      exit 2
    fi

    home_target=""
    if [[ "$scope" != system ]]; then
      [[ -n "$profile" ]] || profile="$(id -un)"
      home_target="$(just _home-target "$profile" "$system" "$os")"
    fi

    if [[ "$scope" != home && "$os" == nixos ]]; then
      just _nixos-hardware-check
      just _nixos-output-check "{{ HOSTNAME }}"
    fi
    if [[ "$scope" != home && "$os" == darwin ]]; then
      host="$(just _darwin-config plan)"
      configurations="$(nix eval --json --no-update-lock-file .#darwinConfigurations --apply builtins.attrNames)"
      if command -v jq >/dev/null 2>&1; then
        jq_cmd=(jq)
      else
        jq_cmd=(nix run nixpkgs#jq --)
      fi
      if ! "${jq_cmd[@]}" -e --arg name "$host" 'index($name) != null' <<< "$configurations" >/dev/null; then
        echo "[x] No nix-darwin output for $host: $configurations" >&2
        exit 2
      fi
    fi

    if [[ "$scope" != home && "$os" == darwin ]]; then
      local_host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
      local_module="${XDG_CONFIG_HOME:-$HOME/.config}/tonys-nix/hosts/$local_host/darwin.nix"
      [[ -f "$local_module" ]] || local_module=""
      echo "[→] darwinConfigurations.$host"
      TONYS_NIX_DARWIN_USER="$(id -un)" TONYS_NIX_DARWIN_LOCAL_CONFIG="$host" \
        TONYS_NIX_DARWIN_LOCAL_MODULE="$local_module" \
        nix build --print-out-paths --no-link --no-update-lock-file --impure \
        ".#darwinConfigurations.${host}.system"
    elif [[ "$scope" != home && "$os" == nixos ]]; then
      echo "[→] nixosConfigurations.{{ HOSTNAME }}"
      nix build --print-out-paths --no-link --no-update-lock-file --impure \
        ".#nixosConfigurations.{{ HOSTNAME }}.config.system.build.toplevel"
    elif [[ "$scope" == system ]]; then
      echo "[✓] No system configuration for $os"
    fi

    if [[ -n "$home_target" ]]; then
      echo "[→] homeConfigurations.$home_target"
      nix build --print-out-paths --no-link --no-update-lock-file \
        ".#homeConfigurations.${home_target}.activationPackage"
    fi

# Verify that the running NixOS hostname selects a declared output.
[private]
_nixos-output-check host:
    #!/usr/bin/env bash
    set -euo pipefail
    host={{ quote(host) }}
    if [[ ! "$host" =~ ^[a-zA-Z0-9_-]+$ ]]; then
      echo "[x] Invalid NixOS hostname: $host" >&2
      exit 2
    fi
    configurations="$(nix eval --json --no-update-lock-file .#nixosConfigurations --apply builtins.attrNames)"
    if command -v jq >/dev/null 2>&1; then
      jq_cmd=(jq)
    else
      jq_cmd=(nix run nixpkgs#jq --)
    fi
    if ! "${jq_cmd[@]}" -e --arg name "$host" 'index($name) != null' <<< "$configurations" >/dev/null; then
      echo "[x] No NixOS output for $host. Available: $("${jq_cmd[@]}" -r 'join(", ")' <<< "$configurations")" >&2
      exit 2
    fi

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
    target=""
    if [[ "$scope" == all || "$scope" == home ]]; then
      [[ -n "$profile" ]] || profile="$(id -un)"
      target="$(just _home-target "$profile" "$system" {{ quote(OS_TYPE) }})"
    fi
    if [[ "{{ OS_TYPE }}" == darwin && ( "$scope" == all || "$scope" == system ) ]]; then
      just _darwin-config >/dev/null
    fi
    if [[ "$scope" == all || "$scope" == system ]]; then
      just _apply-system "$system"
    fi
    if [[ "$scope" == all || "$scope" == home ]]; then
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
      host="$(just _darwin-config)"
      if command -v jq >/dev/null 2>&1; then
        jq_cmd=(jq)
      else
        jq_cmd=(nix run nixpkgs#jq --)
      fi
      configurations="$(nix eval --json --no-update-lock-file .#darwinConfigurations --apply builtins.attrNames)"
      if ! "${jq_cmd[@]}" -e --arg name "$host" 'index($name) != null' <<< "$configurations" >/dev/null; then
        echo "[x] Cannot select a nix-darwin configuration. Available: $("${jq_cmd[@]}" -r 'join(", ")' <<< "$configurations")" >&2
        exit 2
      fi
      echo "[→] nix-darwin configuration: $host"
      local_host="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"
      local_module="${XDG_CONFIG_HOME:-$HOME/.config}/tonys-nix/hosts/$local_host/darwin.nix"
      if [[ ! -f "$local_module" ]]; then
        local_module=""
      else
        echo "[→] Local nix-darwin module: $local_module"
      fi
      login_user="$(id -un)"
      if command -v darwin-rebuild >/dev/null 2>&1; then
        sudo -H env "TONYS_NIX_DARWIN_USER=$login_user" "TONYS_NIX_DARWIN_LOCAL_CONFIG=$host" "TONYS_NIX_DARWIN_LOCAL_MODULE=$local_module" "$(command -v darwin-rebuild)" switch --flake ".#$host" --impure
      else
        sudo -H env "TONYS_NIX_DARWIN_USER=$login_user" "TONYS_NIX_DARWIN_LOCAL_CONFIG=$host" "TONYS_NIX_DARWIN_LOCAL_MODULE=$local_module" "$(command -v nix)" run .#darwin-rebuild -- switch --flake ".#$host" --impure
      fi
      exit 0
    fi
    if [[ "{{ OS_TYPE }}" != "nixos" ]]; then
      exit 0
    fi

    just _nixos-hardware-check
    just _nixos-output-check "{{ HOSTNAME }}"

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
_home-profile-check profile:
    #!/usr/bin/env bash
    set -euo pipefail
    profile={{ quote(profile) }}
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

# Resolve a validated login/profile name to an existing named Home Manager output.
[private]
_home-target profile system os:
    #!/usr/bin/env bash
    set -euo pipefail
    profile={{ quote(profile) }}
    system={{ quote(system) }}
    os={{ quote(os) }}

    just _home-profile-check "$profile"

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

    if ! nix eval --json --no-update-lock-file .#homeConfigurations --apply builtins.attrNames 2>/dev/null \
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
