GC_MIN_INTERVAL_DAYS := "3"
GC_MAX_INTERVAL_DAYS := "14"
GC_DELETE_OLDER_THAN := "3"
GC_STATE_FILE := ".nix-gc-state"

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
