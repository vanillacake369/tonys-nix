{ lib, pkgs, ... }:
{

  home.packages = with pkgs; [
    zsh-autoenv
    zsh-powerlevel10k
  ];

  # Setup for zsh
  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -l";
        kctx = "kubectx";
        kns = "kubens";
        k = "kubectl";
        m = "minikube";
        ka = "kubectl get all -o wide";
        ks = "kubectl get services -o wide";
        kap = "kubectl apply -f ";
        cat = "bat --style=plain --paging=never";
        copy = "xclip -selection clipboard";
        grep = "rg";
        clear = "clear -x";
        claude-monitor = "uv tool run claude-monitor";
      };

      plugins = [
        {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
        }
      ];

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "kubectl"
          "kube-ps1"
        ];
      };

      # zsh script
      initContent = ''
                # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
                # Initialization code that may require console input (password prompts, [y/n]
                # confirmations, etc.) must go above this block; everything else may go below.
                if [[ -r "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
                  source "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
                fi

                # Apply zsh-autoenv
                source ${pkgs.zsh-autoenv}/share/zsh-autoenv/autoenv.zsh

                # Apply zsh-powerlevel10k
        	      source ~/.p10k.zsh

                # Enable home & end key
                case $TERM in (xterm*)
                bindkey '^[[H' beginning-of-line
                bindkey '^[[F' end-of-line
                esac

                # Avoid for Home Manager to manage your shell configuration
                . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

                # Enable session managed by systemd (Linux only)
                ${lib.optionalString pkgs.stdenv.isLinux ''
                  if ! loginctl show-user "$USER" | grep -q "Linger=yes"; then
                    loginctl enable-linger "$USER"
                  fi
                ''}

                # Smart container compose aliases - use podman if available, fallback to docker
                if command -v podman-compose >/dev/null 2>&1; then
                  alias docker-compose='podman-compose'
                elif command -v docker-compose >/dev/null 2>&1; then
                  alias docker-compose='docker-compose'
                fi

                if command -v podman >/dev/null 2>&1; then
                  alias docker-compose-new='podman compose'
                elif command -v docker >/dev/null 2>&1; then
                  alias docker-compose-new='docker compose'
                fi

                # ** Add REPL of fzf [Reference](https://sbulav.github.io/kubernetes/using-fzf-with-kubectl/)**
                # Get manifest of k8s resources :: e.g.) kgjq deploy nginx
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
                # Show proccess
                pslog() {
                  (
                    ps axo pid,rss,comm --no-headers | fzf --preview 'ps o args {1}; ps mu {1}'
                  )
                }
                # Show package dependencies
                pckg-dep() {
                  (
                    apt-cache search . | fzf --preview 'apt-cache depends {1}'
                  )
                }
                # Show systemd
                systemdlog() {
                  (
                    find /etc/systemd/system/  -name "*.service" | \
                      fzf --preview 'cat {}' \
                          --bind "ctrl-i:execute(nvim {})" \
                              --bind "ctrl-s:execute(cat {} | copy)"
                  )
                }
                # Search by keyword
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
                  [[ -n "$matching_files" ]] && ${"\$EDITOR"} "${"\$matching_files"}" -c/$1
                }
      '';
    };

    # Setup for fzf
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      defaultOptions = [
        "--info=inline"
        "--border=rounded"
        "--margin=1"
        "--padding=1"
      ];
    };

  };
}
