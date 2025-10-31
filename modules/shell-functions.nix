# Custom shell functions
# FZF-based utilities for Kubernetes, Git, processes, and system management
{
  config,
  pkgs,
  lib,
  isWsl,
  isDarwin,
  isLinux,
  ...
}: {
  # =============================================================================
  # Custom Shell Functions
  # =============================================================================
  programs.zsh.initExtra = lib.mkAfter ''
    # =============================================================================
    # Custom Functions
    # =============================================================================

    # Kubernetes manifest viewer with fzf
    kube-manifest() {
      kubectl get $* -o name | \
          fzf --preview 'kubectl get {} -o yaml' \
              --bind "ctrl-r:reload(kubectl get $* -o name)" \
              --bind "ctrl-i:execute(kubectl edit {+})" \
              --header 'Ctrl-I: live edit | Ctrl-R: reload list';
    }

    # Git log with preview
    gitlog() {
      (
        git log --oneline | fzf --preview 'git show --color=always {1}'
      )
    }

    # Process viewer
    pslog() {
      (
        ps axo pid,rss,comm --no-headers | fzf --preview 'ps o args {1}; ps mu {1}'
      )
    }

    # Package dependencies viewer
    pckg-dep() {
      (
        apt-cache search . | fzf --preview 'apt-cache depends {1}'
      )
    }

    # Systemd service viewer (Linux)
    ${lib.optionalString pkgs.stdenv.isLinux ''
      systemdlog() {
        (
          find /etc/systemd/system/ -name "*.service" | \
            fzf --preview 'cat {}' \
                --bind "ctrl-i:execute(nvim {})" \
                --bind "ctrl-s:execute(cat {} | copy)"
        )
      }
    ''}

    # Launchd service viewer (macOS)
    ${lib.optionalString pkgs.stdenv.isDarwin ''
      systemdlog() {
        (
          launchctl list | \
            fzf --preview 'launchctl print system/{1} 2>/dev/null || launchctl print user/$(id -u)/{1} 2>/dev/null || echo "Service details not available"' \
                --bind "ctrl-i:execute(nvim /Library/LaunchDaemons/{1}.plist 2>/dev/null || nvim /System/Library/LaunchDaemons/{1}.plist 2>/dev/null || nvim ~/Library/LaunchAgents/{1}.plist 2>/dev/null || echo 'Plist file not found')" \
                --bind "ctrl-s:execute(launchctl print system/{1} 2>/dev/null | pbcopy || launchctl print user/$(id -u)/{1} 2>/dev/null | pbcopy)" \
                --header 'Ctrl-I: edit plist | Ctrl-R: reload list | Ctrl-S: copy service info'
        )
      }
    ''}

    # Search files by keyword with fzf
    search() {
      [[ $# -eq 0 ]] && { echo "provide regex argument"; return }
      local matching_files
      case $1 in
        -h)
          shift
          matching_files=$(rg -l --hidden $1 | fzf --exit-0 --preview="rg --color=always -n -A 20 '$1' {} ")
          ;;
        *)
          matching_files=$(rg -l -- $1 | fzf --exit-0 --preview="rg --color=always -n -A 20 -- '$1' {} ")
          ;;
      esac
      [[ -n "$matching_files" ]] && $EDITOR "$matching_files" -c/$1
    }
  '';
}
