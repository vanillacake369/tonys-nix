set shell := ["bash", "-euo", "pipefail", "-c"]

########### Global Settings ##########

HOSTNAME := `hostname`
OS_TYPE := `case "$(uname -s)" in
  Darwin) echo darwin ;;
  Linux)
    if [[ -d /etc/nixos ]]; then
      echo nixos
    elif grep -qiE '(Microsoft|WSL)' /proc/version 2>/dev/null; then
      echo wsl
    else
      echo linux
    fi
    ;;
  *) echo unsupported ;;
esac`
SYSTEM_ARCH := `case "$(uname -s):$(uname -m)" in
  Darwin:arm64) echo aarch64-darwin ;;
  Darwin:*) echo unsupported ;;
  Linux:aarch64) echo aarch64-linux ;;
  Linux:x86_64) echo x86_64-linux ;;
  Linux:amd64) echo x86_64-linux ;;
  *) echo unsupported ;;
esac`
GC_MIN_INTERVAL_DAYS := "3"
GC_MAX_INTERVAL_DAYS := "14"
GC_DELETE_OLDER_THAN := "3"
GC_STATE_FILE := ".nix-gc-state"
APPLY_RETRY_THRESHOLD := "3"
APPLY_FALLBACK_SUBSTITUTERS := "https://cache.nixos.org"
MAC_SLEEP_TIME := "02:00:00"
MAC_WAKE_TIME := "06:30:00"
MAC_SCHEDULE_DAYS := "MTWRFSU"
NIX_CONF_SOURCE := justfile_directory() + "/dotfiles/nix/nix.conf"
NIX_CONF_TARGET := "/etc/nix/nix.conf"
AEROSPACE_CONFIG_PATH := "modules/keymap"
BREWFILE := justfile_directory() + "/Brewfile"
BREW_SYNC_DIR := justfile_directory() + "/.cache/brew"

########### Public Command Surface ##########

# NOTE:
#   bare `just`는 조회용 help가 아니라 이 저장소의 의도적인 수렴 명령이다.
#   모든 check가 통과한 경우에만 apply를 실행해 실패 상태의 구성이
#   호스트에 반영되지 않도록 fail-closed 순서를 유지한다.
# Run every check and apply the current login user's complete profile.
[default]
default:
    #!/usr/bin/env bash
    echo "[1/2] Running all checks"
    just check all
    echo "[2/2] Applying the current profile"
    just apply all

# Synchronize managed applications. Domains: brew, raycast.
sync domain action="guide" target="local":
    #!/usr/bin/env bash
    case {{ quote(domain) }} in
      brew)
        case {{ quote(action) }} in
          check|export|import) just brew {{ quote(action) }} {{ quote(target) }} ;;
          *) echo "[x] Usage: just sync brew {check|export|import} [local|user@host]" >&2; exit 2 ;;
        esac
        ;;
      raycast)
        [[ {{ quote(target) }} == local ]] || { echo "[x] Raycast guide does not accept a target" >&2; exit 2; }
        just raycast {{ quote(action) }}
        ;;
      *) echo "[x] Expected: just sync {brew|raycast} ..." >&2; exit 2 ;;
    esac

# Set up this machine. Actions: all, nix, home, agents, mac, completions.
setup action:
    #!/usr/bin/env bash
    case {{ quote(action) }} in
      all) just bootstrap ;;
      nix) just install-nix && just system-link-nix-conf ;;
      home) just install-home-manager && just apply home ;;
      agents) just agent-login ;;
      mac) just sync-local-integrations ;;
      completions) just _setup-completions ;;
      *) echo "[x] Expected: just setup {all|nix|home|agents|mac|completions}" >&2; exit 2 ;;
    esac

# Run quality gates. Targets: all, flake, hooks, lint.
check target="all":
    #!/usr/bin/env bash
    case {{ quote(target) }} in
      all) just lint && just test ;;
      flake) just _test-flake ;;
      hooks) just test-hooks ;;
      lint) just lint ;;
      *) echo "[x] Expected: just check {all|flake|hooks|lint}" >&2; exit 2 ;;
    esac

# Run maintenance operations. Domains: gc, health.
maintenance domain action="auto":
    #!/usr/bin/env bash
    case {{ quote(domain) }} in
      gc)
        case {{ quote(action) }} in
          auto) just gc ;;
          force) just gc-force ;;
          status) just gc-info ;;
          *) echo "[x] Expected: just maintenance gc {auto|force|status}" >&2; exit 2 ;;
        esac
        ;;
      health)
        [[ {{ quote(action) }} == auto ]] || { echo "[x] Usage: just maintenance health" >&2; exit 2; }
        just performance-test
        ;;
      *) echo "[x] Expected: just maintenance {gc|health}" >&2; exit 2 ;;
    esac

# Build or inspect image outputs. Actions: list, build, build-arch, build-all, show.
image action="list" arg="" arch="":
    #!/usr/bin/env bash
    case {{ quote(action) }} in
      list)
        [[ -z {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image list" >&2; exit 2; }
        just list-image-formats
        ;;
      build)
        [[ -n {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image build <format>" >&2; exit 2; }
        just build-image {{ quote(arg) }}
        ;;
      build-arch)
        [[ -n {{ quote(arg) }} && -n {{ quote(arch) }} ]] || { echo "[x] Usage: just image build-arch <format> <arch>" >&2; exit 2; }
        just build-image-arch {{ quote(arg) }} {{ quote(arch) }}
        ;;
      build-all)
        [[ -z {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image build-all" >&2; exit 2; }
        just build-images
        ;;
      show)
        [[ -z {{ quote(arg) }} && -z {{ quote(arch) }} ]] || { echo "[x] Usage: just image show" >&2; exit 2; }
        just show-images
        ;;
      *) echo "[x] Expected: just image {list|build|build-arch|build-all|show}" >&2; exit 2 ;;
    esac

########### Bootstrap ##########

# Full first-time setup for the current machine.
[private]
bootstrap:
    #!/usr/bin/env bash
    just install-nix
    just system-link-nix-conf
    just install-home-manager
    just bootstrap-uidmap
    just apply
    just gc

# Authenticate missing AI providers via cli-proxy-api OAuth.
[private]
agent-login:
    #!/usr/bin/env bash
    AUTH_DIR="$HOME/.cli-proxy-api"
    CONFIG="-config $AUTH_DIR/config.yaml"
    has_auth() { ls "$AUTH_DIR"/$1-*.json 2>/dev/null | head -1 | grep -q .; }
    MISSING=()
    has_auth gemini || MISSING+=(gemini)
    has_auth claude || MISSING+=(claude)
    has_auth codex  || MISSING+=(codex)
    if [[ ${#MISSING[@]} -eq 0 ]]; then
        echo "[✓] All AI providers authenticated"
        exit 0
    fi
    echo "[!] Missing auth: ${MISSING[*]}"
    for p in "${MISSING[@]}"; do
        case $p in
            gemini) echo "[→] Logging in to Gemini (Google)..." && cli-proxy-api -login $CONFIG ;;
            claude) echo "[→] Logging in to Claude (Anthropic)..." && cli-proxy-api -claude-login $CONFIG ;;
            codex)  echo "[→] Logging in to Codex (OpenAI)..." && cli-proxy-api -codex-login $CONFIG ;;
        esac
    done
    echo "[✓] Agent login complete"

# Install Nix if it is not available.
[private]
install-nix:
    #!/usr/bin/env bash
    if command -v nix >/dev/null 2>&1; then
      echo "[✓] Nix is already installed"
      exit 0
    fi

    echo "[!] Installing Nix"
    sh <(curl -L https://nixos.org/nix/install) --daemon

# Prepare Home Manager. On fresh systems the real install happens via flake commands.
[private]
install-home-manager:
    #!/usr/bin/env bash
    if command -v home-manager >/dev/null 2>&1; then
      echo "[✓] Home Manager is already installed"
      exit 0
    fi

    echo "[!] Home Manager not found - it will be bootstrapped via flake on apply"
    if nix-channel --list 2>/dev/null | grep -q '^home-manager'; then
      echo "[!] Removing legacy home-manager channel"
      nix-channel --remove home-manager
    fi

# Install uidmap only where it is relevant.
[private]
bootstrap-uidmap:
    #!/usr/bin/env bash
    case "{{ OS_TYPE }}" in
      darwin)
    echo "[✓] uidmap install skipped on macOS"
    ;;
      linux|wsl)
    just install-uidmap
    ;;
      nixos)
    echo "[✓] uidmap install skipped on NixOS"
    ;;
      *)
    echo "[→] uidmap install skipped on unsupported platform: {{ OS_TYPE }}"
    ;;
    esac

# Install uidmap on Debian/Ubuntu style Linux hosts.
[private]
install-uidmap:
    #!/usr/bin/env bash
    if [[ "$(uname -s)" != "Linux" ]]; then
      echo "[→] uidmap install skipped on $(uname -s)"
      exit 0
    fi

    if command -v newuidmap >/dev/null 2>&1 && command -v newgidmap >/dev/null 2>&1; then
      echo "[✓] newuidmap and newgidmap already exist"
      exit 0
    fi

    echo "[!] Installing uidmap via apt (requires sudo)"
    sudo apt update
    sudo apt install -y uidmap

# Apply the current login user's profile. Scopes: all, home, system.
apply scope="all" profile="":
    #!/usr/bin/env bash
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
      echo "User: $profile"
      echo "Platform: {{ OS_TYPE }} ($system)"
      echo "Target: $target"
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
    echo "[✓] Apply target validated: {{ target }}"
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
    if [[ "{{ OS_TYPE }}" != "nixos" ]]; then
      echo "[→] System apply skipped - not NixOS"
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

    if ! nix eval --json .#homeConfigurations --apply builtins.attrNames \
      | jq -e --arg target "$target" 'index($target) != null' >/dev/null; then
      echo "[x] Flake output not found: homeConfigurations.$target" >&2
      echo "    Ensure user/${profile}.nix declares username = \"${profile}\"." >&2
      exit 2
    fi
    printf '%s\n' "$target"

# Apply an already-resolved Home Manager target.
[private]
_apply-home flake_target:
    #!/usr/bin/env bash
    if command -v home-manager >/dev/null 2>&1; then
      hm_cmd=(home-manager)
      hm_fallback_cmd=(home-manager switch --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}")
    else
      echo "[!] Bootstrapping Home Manager via flake"
      hm_cmd=(nix run home-manager/master --)
      hm_fallback_cmd=(nix --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}" run home-manager/master -- switch --option substituters "{{ APPLY_FALLBACK_SUBSTITUTERS }}")
    fi

    flake_target={{ quote(flake_target) }}

    echo "[!] Applying Home Manager target: ${flake_target}"
    echo "Running: ${hm_cmd[*]} switch --flake .#${flake_target} -b back"
    retry_threshold="{{ APPLY_RETRY_THRESHOLD }}"
    attempt=1
    while (( attempt <= retry_threshold )); do
      echo "[→] Attempt ${attempt}/${retry_threshold}: ${hm_cmd[*]} switch --flake .#${flake_target} -b back"
      if "${hm_cmd[@]}" switch --flake ".#${flake_target}" -b back; then
        exit 0
      fi
      echo "[!] Home Manager apply failed on attempt ${attempt}/${retry_threshold}"
      (( attempt++ ))
    done

    echo "[!] Falling back to substituters={{ APPLY_FALLBACK_SUBSTITUTERS }}"
    "${hm_fallback_cmd[@]}" --flake ".#${flake_target}" -b back

# Sync local desktop integrations after configuration changes are applied.
[private]
sync-local-integrations:
    #!/usr/bin/env bash
    just apply-fish
    just reload-aerospace-if-needed
    just setup-mac-power-schedule

########### macOS Application Sync ##########

# Manage the shared Brewfile locally or through an explicit Tailscale SSH target.
[private]
brew action target="local":
    #!/usr/bin/env bash
    case {{ quote(action) }} in
      check) just _brew-check {{ quote(target) }} ;;
      export) just _brew-export {{ quote(target) }} ;;
      import) just _brew-import {{ quote(target) }} ;;
      *) echo "[✗] Expected: just brew {check|export|import} [local|[user@]tailscale-host]"; exit 1 ;;
    esac

# Print the supported GUI workflow for Raycast configuration migration.
[private]
raycast action="guide":
    #!/usr/bin/env bash
    action={{ quote(action) }}
    case "$action" in
      export)
        printf '%s\n' \
          "Raycast configuration export requires the Raycast GUI:" \
          "  1. Open Raycast on the source Mac." \
          "  2. Run 'Export Settings & Data', or open Settings > Advanced > Export." \
          "  3. Set or enter an export passphrase (at least 8 characters)." \
          "  4. Save the encrypted .rayconfig file and transfer it securely." \
          "" \
          "Raycast has no supported headless CLI for this export."
        ;;
      import)
        printf '%s\n' \
          "Raycast configuration import requires the Raycast GUI:" \
          "  1. On the target Mac, double-click the transferred .rayconfig file." \
          "  2. Enter its export passphrase in Raycast." \
          "  3. Select the categories to import and confirm." \
          "  4. Run 'just sync raycast verify' for the manual verification checklist." \
          "" \
          "Import merges data; it does not make the target an exact overwrite of the source."
        ;;
      status|verify)
        printf '%s\n' \
          "Verify the imported configuration inside Raycast:" \
          "  1. Open Settings and confirm expected extensions are installed and enabled." \
          "  2. Check Settings, Aliases & Hotkeys for the expected shortcuts." \
          "  3. Confirm representative Quicklinks, Snippets, and other selected categories." \
          "  4. Run one imported command and one imported hotkey." \
          "" \
          "Raycast provides no supported CLI that can attest to a completed import."
        ;;
      guide)
        printf '%s\n' \
          "Raycast configuration migration is GUI-only." \
          "Run one of:" \
          "  just sync raycast export" \
          "  just sync raycast import" \
          "  just sync raycast verify"
        ;;
      *)
        echo "[✗] Expected: just sync raycast {guide|export|import|verify}"
        exit 2
        ;;
    esac

[private]
_brew-check target:
    #!/usr/bin/env bash
    target={{ quote(target) }}
    case "$target" in
      local)
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "{{ BREWFILE }}" --no-upgrade
        ;;
      -*|*[[:space:][:cntrl:]]*|'')
        echo "[✗] Invalid Brew target: $target"
        exit 1
        ;;
      *)
        tailscale ssh "$target" \
          'HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew bundle check --file=- --no-upgrade' < "{{ BREWFILE }}"
        ;;
    esac

[private]
_brew-import target:
    #!/usr/bin/env bash
    target={{ quote(target) }}
    echo "[→] Brew import target: $target (additive, no upgrade, no cleanup)"
    case "$target" in
      local)
        HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file "{{ BREWFILE }}" --no-upgrade
        ;;
      -*|*[[:space:][:cntrl:]]*|'')
        echo "[✗] Invalid Brew target: $target"
        exit 1
        ;;
      *)
        tailscale ssh "$target" \
          'HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew bundle install --file=- --no-upgrade' < "{{ BREWFILE }}"
        ;;
    esac

[private]
_brew-export target:
    #!/usr/bin/env bash
    target={{ quote(target) }}
    case "$target" in
      -*|*[[:space:][:cntrl:]]*|'')
        echo "[✗] Invalid Brew target: $target"
        exit 1
        ;;
    esac
    mkdir -p "{{ BREW_SYNC_DIR }}"
    target_label=remote
    [[ "$target" == local ]] && target_label=local
    candidate="{{ BREW_SYNC_DIR }}/Brewfile.${target_label}.$(date +%Y%m%d-%H%M%S)"
    case "$target" in
      local)
        if ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file=- --force --no-describe > "$candidate"; then
          unlink "$candidate" 2>/dev/null || true
          exit 1
        fi
        ;;
      *)
        if ! tailscale ssh "$target" \
          'HOMEBREW_NO_AUTO_UPDATE=1 /opt/homebrew/bin/brew bundle dump --file=- --force --no-describe' > "$candidate"; then
          unlink "$candidate" 2>/dev/null || true
          exit 1
        fi
        ;;
    esac
    if [[ ! -s "$candidate" ]]; then
      unlink "$candidate" 2>/dev/null || true
      echo "[✗] Brew export is empty"
      exit 1
    fi
    diff -u "{{ BREWFILE }}" "$candidate" || true
    if [[ -t 0 ]]; then
      read -r -p "Replace Brewfile with this export? [y/N] " answer
    else
      answer="n"
    fi
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      cp "$candidate" "{{ BREWFILE }}"
      echo "[✓] Updated {{ BREWFILE }}"
    else
      echo "[→] Kept candidate at $candidate"
    fi

# Reload AeroSpace when its config changed in git and the local environment supports it.
[private]
reload-aerospace-if-needed:
    #!/usr/bin/env bash
    if [[ "{{ OS_TYPE }}" != "darwin" ]]; then
      echo "[→] AeroSpace reload skipped - not macOS"
      exit 0
    fi

    if ! command -v aerospace >/dev/null 2>&1; then
      echo "[→] AeroSpace reload skipped - aerospace is not installed"
      exit 0
    fi

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "[→] AeroSpace reload skipped - not in a git worktree"
      exit 0
    fi

    if [[ -z "$(git status --porcelain -- "{{ AEROSPACE_CONFIG_PATH }}")" ]]; then
      echo "[→] AeroSpace reload skipped - no git changes in {{ AEROSPACE_CONFIG_PATH }}"
      exit 0
    fi

    echo "[!] Reloading AeroSpace config"
    if reload_output="$(aerospace reload-config 2>&1)"; then
      echo "[✓] AeroSpace config reloaded"
      exit 0
    fi

    reload_status=$?
    printf '%s\n' "$reload_output"
    if grep -q "versions are incompatible" <<<"$reload_output"; then
      echo "[!] AeroSpace reload failed - running app is from an older build; restart AeroSpace and run reload again"
      exit 0
    fi

    echo "[!] AeroSpace reload failed with exit code ${reload_status}"
    exit 0

# Ensure the Nix-provided fish is registered as a login shell.
[private]
apply-fish:
    #!/usr/bin/env bash
    fish_path="$HOME/.nix-profile/bin/fish"
    if ! grep -qx "$fish_path" /etc/shells; then
      echo "[!] Adding $fish_path to /etc/shells (requires sudo)"
      echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi

    current_shell=""
    case "{{ OS_TYPE }}" in
      darwin)
        current_shell=$(dscl . -read "$HOME" UserShell | awk '{print $2}')
        ;;
      linux|wsl|nixos)
        current_shell=$(getent passwd "$USER" | cut -d: -f7)
        ;;
      *)
        current_shell="$SHELL"
        ;;
    esac

    if [[ "$current_shell" != "$fish_path" ]]; then
      echo "[!] Changing default shell to $fish_path (may ask for password)"
      chsh -s "$fish_path"
    else
      echo "[✓] fish is already the default shell"
    fi

########### System Configuration ##########

# Link the repository nix.conf into /etc/nix/nix.conf.
[private]
system-link-nix-conf:
    #!/usr/bin/env bash
    source_file="{{ NIX_CONF_SOURCE }}"
    target_file="{{ NIX_CONF_TARGET }}"

    if [[ ! -f "$source_file" ]]; then
      echo "[✗] Source file not found: $source_file"
      exit 1
    fi

    if [[ ! -d /etc/nix ]]; then
      echo "[!] Creating /etc/nix (requires sudo)"
      sudo mkdir -p /etc/nix
    fi

    if [[ -L "$target_file" ]]; then
      current_target=$(readlink "$target_file")
      if [[ "$current_target" == "$source_file" ]]; then
    echo "[✓] nix.conf symlink already configured"
    exit 0
      fi

      echo "[!] Removing existing nix.conf symlink: $current_target"
      sudo rm "$target_file"
    elif [[ -e "$target_file" ]]; then
      echo "[!] Backing up existing nix.conf to ${target_file}.backup"
      sudo mv "$target_file" "${target_file}.backup"
    fi

    echo "[!] Linking $target_file -> $source_file"
    sudo ln -s "$source_file" "$target_file"
    echo "[✓] nix.conf linked successfully"

# Configure daily sleep and wake scheduling on macOS.
[private]
setup-mac-power-schedule:
    #!/usr/bin/env bash
    if [[ "{{ OS_TYPE }}" != "darwin" ]]; then
      echo "[✓] Power schedule setup skipped - not macOS"
      exit 0
    fi

    parse_pmset_time() {
      local line="$1"
      local time_part
      local hour
      local min
      local ampm

      time_part="$(grep -oE '[0-9]{1,2}:[0-9]{2}(AM|PM)' <<<"$line" | head -1 || true)"
      if [[ -z "$time_part" ]]; then
    return 0
      fi

      hour="$(cut -d: -f1 <<<"$time_part")"
      min="$(grep -oE '[0-9]+' <<<"$(cut -d: -f2 <<<"$time_part")")"
      ampm="$(grep -oE '(AM|PM)' <<<"$time_part")"

      if [[ "$ampm" == "PM" && "$hour" -ne 12 ]]; then
    hour=$((hour + 12))
      elif [[ "$ampm" == "AM" && "$hour" -eq 12 ]]; then
    hour=0
      fi

      printf "%02d:%02d:00" "$hour" "$min"
    }

    current_schedule="$(pmset -g sched 2>/dev/null || true)"
    repeating_section="$(sed -n '/Repeating power events:/,/Scheduled power events:/p' <<<"$current_schedule" || echo "$current_schedule")"

    sleep_line="$(grep -i 'sleep at' <<<"$repeating_section" || true)"
    wake_line="$(grep -iE '(wake|wakepoweron|wakeorpoweron).*at' <<<"$repeating_section" || true)"
    has_sleep="$(parse_pmset_time "$sleep_line")"
    has_wake="$(parse_pmset_time "$wake_line")"

    if [[ -n "$has_sleep" && -n "$has_wake" ]] && [[ "$has_sleep" == "{{ MAC_SLEEP_TIME }}" ]] && [[ "$has_wake" == "{{ MAC_WAKE_TIME }}" ]]; then
      echo "[✓] Power schedule already configured"
      echo "    Sleep: {{ MAC_SLEEP_TIME }} | Wake: {{ MAC_WAKE_TIME }}"
      exit 0
    fi

    if [[ -n "$has_sleep" || -n "$has_wake" ]]; then
      echo "[!] Current schedule detected"
      [[ -n "$has_sleep" ]] && echo "    Sleep: $has_sleep"
      [[ -n "$has_wake" ]] && echo "    Wake: $has_wake"
      echo "    New: sleep {{ MAC_SLEEP_TIME }} / wake {{ MAC_WAKE_TIME }}"
    else
      echo "[!] No existing macOS power schedule detected"
      echo "    New: sleep {{ MAC_SLEEP_TIME }} / wake {{ MAC_WAKE_TIME }}"
    fi

    read -r -p "Apply macOS power schedule? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "[→] Power schedule setup skipped"
      exit 0
    fi

    sudo pmset repeat cancel >/dev/null 2>&1 || true
    sudo pmset repeat sleep {{ MAC_SCHEDULE_DAYS }} {{ MAC_SLEEP_TIME }} wakeorpoweron {{ MAC_SCHEDULE_DAYS }} {{ MAC_WAKE_TIME }}

    echo "[✓] Power schedule configured"
    echo "    Verify: sudo pmset -g sched"
    echo "    Cancel: sudo pmset repeat cancel"

# Enable shared mount propagation for rootless Podman.
[private]
enable-shared-mount:
    #!/usr/bin/env bash
    propagation="$(findmnt -no PROPAGATION /)"
    if [[ "$propagation" == *shared* ]]; then
      echo "[✓] Shared mount propagation is already configured"
      exit 0
    fi

    echo "[!] Configuring shared mount propagation for Podman"
    sudo mount --make-rshared /
    echo "[✓] Shared mount propagation configured"

########### Maintenance ##########

# Persist a GC run timestamp.
[private]
gc-record:
    #!/usr/bin/env bash
    date +%s > {{ GC_STATE_FILE }}
    echo "[✓] GC execution recorded at $(date)"

# Run conditional garbage collection using age and disk pressure.
[private]
gc:
    #!/usr/bin/env bash
    days_since_gc=999

    if [[ -f "{{ GC_STATE_FILE }}" ]]; then
      last_gc="$(cat {{ GC_STATE_FILE }} 2>/dev/null || echo 0)"
      current="$(date +%s)"
      if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
    days_since_gc=$(((current - last_gc) / 86400))
      fi
    fi

    run_gc() {
      nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}d
      if [[ "{{ OS_TYPE }}" == "nixos" ]]; then
    sudo -H nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}d
      fi
      just gc-record
    }

    if (( days_since_gc >= {{ GC_MAX_INTERVAL_DAYS }} )); then
      echo "[!] Running GC (${days_since_gc} days since last cleanup)"
      run_gc
      exit 0
    fi

    if (( days_since_gc < {{ GC_MIN_INTERVAL_DAYS }} )); then
      echo "[→] GC skipped (${days_since_gc} days since last cleanup)"
      echo "    Use 'just gc-force' to force cleanup"
      exit 0
    fi

    if [[ ! -d /nix/store ]]; then
      echo "[→] GC skipped (/nix/store not found)"
      exit 0
    fi

    used_percent="$(df /nix/store 2>/dev/null | awk 'END {gsub(/%/, "", $5); print $5}')"
    if [[ -n "$used_percent" && "$used_percent" -gt 80 ]]; then
      echo "[!] Running GC (disk usage ${used_percent}%)"
      run_gc
    else
      echo "[→] GC skipped (${days_since_gc} days since cleanup, ${used_percent:-unknown}% disk used)"
      echo "    Use 'just gc-force' to force cleanup"
    fi

# Run garbage collection immediately.
[private]
gc-force:
    #!/usr/bin/env bash
    echo "[!] Force running home manager GC"
    home-manager expire-generations "-{{ GC_DELETE_OLDER_THAN }} days"

    echo "[!] Force running garbage collection"
    nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}d

    if [[ "{{ OS_TYPE }}" == "nixos" ]]; then
      echo "[!] Running system-wide garbage collection"
      sudo -H nix-collect-garbage -d --delete-older-than {{ GC_DELETE_OLDER_THAN }}d
    fi

    echo "[!] Running nix store optimization"
    nix store optimise

    just gc-record
    echo "[✓] Forced garbage collection & store optimization completed"

# Show GC-related status for this machine.
[private]
gc-info:
    #!/usr/bin/env bash
    echo "=== Garbage Collection Status ==="
    echo "Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo N/A)"

    if [[ -f "{{ GC_STATE_FILE }}" ]]; then
      last_gc="$(cat {{ GC_STATE_FILE }} 2>/dev/null || echo 0)"
      current="$(date +%s)"
      if [[ "$last_gc" =~ ^[0-9]+$ ]]; then
    echo "Days since last GC: $(((current - last_gc) / 86400))"
      else
    echo "Days since last GC: Unknown (corrupted state)"
      fi
    else
      echo "Days since last GC: Never"
    fi

    if [[ -d /nix/store ]]; then
      used_percent="$(df /nix/store 2>/dev/null | awk 'END {print $5}')"
      echo "Disk usage: ${used_percent:-N/A}"
    fi

    echo
    echo "Min interval: {{ GC_MIN_INTERVAL_DAYS }} days"
    echo "Max interval: {{ GC_MAX_INTERVAL_DAYS }} days"
    echo "Delete older than: {{ GC_DELETE_OLDER_THAN }} days"
    echo "State file: {{ GC_STATE_FILE }}"

########### Quality Gate ##########

# Run guard tests (nix eval) + shell hook tests (bats).
[private]
test: test-hooks
    just _test-flake

# Build every flake check for the current system.
[private]
_test-flake:
    #!/usr/bin/env bash
    nix eval .#checks.{{ SYSTEM_ARCH }} --apply builtins.attrNames --json | jq -r '.[]' | while IFS= read -r check; do
      echo "[!] Running flake check: $check"
      if ! out=$(nix build --print-out-paths ".#checks.{{ SYSTEM_ARCH }}.$check" --no-link); then
        echo "[✗] Flake check failed: $check"
        exit 1
      fi
      if [[ "$check" == "guard-tests" ]]; then
        result=$(cat "$out")
        total=$(echo "$result" | jq -r .total)
        passed=$(echo "$result" | jq -r .passed)
        echo "[✓] $passed/$total guard tests passed"
        if [[ "$total" != "$passed" ]]; then exit 1; fi
      fi
    done

# Install only Just's Fish completion; do not activate the Home Manager profile.
[private]
_setup-completions:
    #!/usr/bin/env bash
    source_file="{{ justfile_directory() }}/completions/just-tonys-nix.fish"
    completion="$HOME/.config/fish/completions/just.fish"
    mkdir -p "$(dirname "$completion")"
    candidate="$(mktemp "${completion}.tmp.XXXXXX")"
    trap 'rm -f "$candidate"' EXIT
    cp "$source_file" "$candidate"

    if [[ -f "$completion" ]] && cmp -s "$candidate" "$completion"; then
      echo "[✓] Just Fish completion is already up to date: $completion"
    else
      chmod 0644 "$candidate"
      mv -f "$candidate" "$completion"
      echo "[✓] Installed Just Fish completion: $completion"
    fi
    echo "    tonys-nix candidates activate only inside this repository."

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

# Run linters (deadnix, statix, alejandra).
[private]
lint:
    #!/usr/bin/env bash
    echo "[!] deadnix (unused code)..."
    deadnix --fail .
    echo "[!] statix (anti-patterns)..."
    statix check .
    echo "[!] alejandra (formatting)..."
    alejandra --check .

########### Diagnostics ##########

# Run a practical health check for this Nix setup.
[private]
performance-test:
    #!/usr/bin/env bash
    echo "=== Nix Performance Test ==="
    echo "Timestamp: $(date)"
    echo

    echo "1. Store metrics"
    echo "   Store size: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo N/A)"
    echo "   Store paths: $(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    echo "   Disk usage: $(df -h /nix/store 2>/dev/null | awk 'END {print $3 \"/\" $2 \" (\" $5 \" full)\"}' || echo N/A)"
    echo

    echo "2. Nix configuration"
    echo "   Auto-optimise: $(grep 'auto-optimise-store' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | xargs || echo N/A)"
    echo "   Max jobs: $(grep 'max-jobs' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | xargs || echo N/A)"
    echo "   Cores: $(grep 'cores' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | xargs || echo N/A)"
    echo "   CPU cores available: $(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu 2>/dev/null || echo N/A)"
    echo

    echo "3. Binary cache"
    echo "   Substituters:"
    grep 'substituters' /etc/nix/nix.conf 2>/dev/null | cut -d= -f2 | tr ' ' '\n' | sed 's/^/     - /' || true
    echo

    echo "4. Garbage collection"
    if command -v systemctl >/dev/null 2>&1 && systemctl is-enabled nix-gc.timer >/dev/null 2>&1; then
      echo "   GC Timer: $(systemctl is-enabled nix-gc.timer) ($(systemctl is-active nix-gc.timer))"
      echo "   GC Schedule: $(systemctl show nix-gc.timer | grep OnCalendar | cut -d= -f2)"
    else
      echo "   GC Timer: Not available via systemctl"
    fi
    echo

    echo "5. Quick shell test"
    start_time="$(date +%s.%N 2>/dev/null || date +%s)"
    nix shell nixpkgs#hello --command hello >/dev/null 2>&1 || true
    end_time="$(date +%s.%N 2>/dev/null || date +%s)"
    duration="$(echo "$end_time - $start_time" | bc 2>/dev/null || echo N/A)"
    echo "   hello test: ${duration}s"
    echo

    echo "6. Store optimization"
    echo "   Symlinks in store: $(find /nix/store -type l 2>/dev/null | wc -l | tr -d ' ')"
    echo

    echo "7. Smart GC summary"
    echo "   GC interval: {{ GC_MIN_INTERVAL_DAYS }}-{{ GC_MAX_INTERVAL_DAYS }} days"
    if [[ -d /nix/store ]]; then
      used_percent="$(df /nix/store 2>/dev/null | awk 'END {gsub(/%/, "", $5); print $5}')"
      echo "   Disk usage: ${used_percent}%"
      if [[ "$used_percent" -gt 80 ]]; then
    echo "   Recommendation: cleanup needed"
      else
    echo "   Recommendation: store is clean"
      fi
    fi

########### Images ##########

# List supported image outputs.
[private]
list-image-formats:
    #!/usr/bin/env bash
    echo "Available image formats for {{ SYSTEM_ARCH }}:"
    echo
    echo "Format        Description"
    echo "----------    -----------"
    echo "iso           Bootable ISO image"
    echo "virtualbox    VirtualBox OVA image"
    echo "vmware        VMware VMDK image"
    echo "qcow          QEMU qcow image"
    echo
    echo "Usage: just build-image <format>"
    echo "Note: For containers, use official NixOS Docker images instead."

# Build one image format for the current architecture.
[private]
build-image format:
    #!/usr/bin/env bash
    echo "[!] Building {{ format }} image for {{ SYSTEM_ARCH }}"
    nix build .#"{{ format }}"
    echo "[✓] Build complete: $(readlink result)"

# Build one image format for a specific architecture.
[private]
build-image-arch format arch:
    echo "[!] Building {{ format }} image for {{ arch }}"
    nix build .#packages."{{ arch }}"."{{ format }}"
    echo "[✓] Build complete: $(readlink result)"

# Build all supported image formats for the current architecture.
[private]
build-images:
    #!/usr/bin/env bash
    failed=()
    for format in iso virtualbox vmware qcow; do
      echo "[!] Building $format"
      if nix build ".#$format"; then
    echo "[✓] $format built successfully"
      else
    echo "[✗] $format build failed"
    failed+=("$format")
      fi
      echo
    done

    if [[ "${#failed[@]}" -gt 0 ]]; then
      echo "[✗] Failed formats: ${failed[*]}"
      exit 1
    fi

    echo "[✓] All image formats built successfully"

# Show local build artifacts produced by image builds.
[private]
show-images:
    #!/usr/bin/env bash
    echo "Built images in ./result*:"
    ls -lh result* 2>/dev/null | awk '{print $9, $5}' | column -t || echo "No images found. Run 'just build-image <format>' first."

########### Destructive / Legacy Cleanup ##########

# Uninstall Home Manager from the current profile.
[private]
uninstall-home-manager:
    #!/usr/bin/env bash
    echo y | home-manager uninstall

# Remove local editor and shell configs created by previous setups.
[private]
purge-local-configs:
    #!/usr/bin/env bash
    read -r -p "This removes local config directories and purges apt zsh. Continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "[→] Purge cancelled"
      exit 0
    fi

    rm -rf ~/.config/nvim
    rm -rf ~/.local/share/nvim
    rm -rf ~/.cache/nvim
    rm -rf ~/.nix-profile/bin/spacevim
    rm -rf ~/.SpaceVim*
    rm -rf ~/.zshrc
    sudo apt-get --purge remove -y zsh
