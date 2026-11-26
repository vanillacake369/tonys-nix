MAC_SLEEP_TIME := "02:00:00"
MAC_WAKE_TIME := "06:30:00"
MAC_SCHEDULE_DAYS := "MTWRFSU"
AEROSPACE_CONFIG_PATH := "dotfiles/keymap"
# Synchronize managed applications for this host.
sync domain action="guide":
    #!/usr/bin/env bash
    case {{ quote(domain) }} in
      brew)
        case {{ quote(action) }} in
          guide|sync)
            if [[ "{{ OS_TYPE }}" != darwin ]]; then
              echo "[x] Homebrew sync requires macOS" >&2
              exit 1
            fi
            just apply system
            ;;
          *) echo "[x] Usage: just sync brew" >&2; exit 2 ;;
        esac
        ;;
      raycast)
        just raycast {{ quote(action) }}
        ;;
      *) echo "[x] Expected: just sync {brew|raycast} ..." >&2; exit 2 ;;
    esac

# Sync local desktop integrations after configuration changes are applied.
[private]
sync-local-integrations:
    #!/usr/bin/env bash
    just sync brew
    just apply-fish
    just reload-aerospace-if-needed
    just setup-mac-power-schedule

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

    if [[ -z "$(git status --porcelain -- "{{ AEROSPACE_CONFIG_PATH }}" modules/keymap.home.nix lib/keymap-to-aerospace.nix lib/keymap-to-karabiner.nix)" ]]; then
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
