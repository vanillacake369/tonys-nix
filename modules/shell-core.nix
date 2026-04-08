# Core shell environment configuration
# Fish, FZF, and basic shell setup
{
  pkgs,
  lib,
  isDarwin,
  isLinux,
  ...
}: {
  # =============================================================================
  # Fish Shell Configuration
  # =============================================================================
  programs = {
    fish = {
      enable = true;

      # 1. Shell Aliases & Abbreviations
      shellAliases = {
        ll = "ls -l";
        cat = "bat --style=plain --paging=never";
        grep = "rg";
        clear = "clear -x";
        # Kubernetes
        k = "kubectl";
        m = "minikube";
        kctx = "kubectx";
        ka = "kubectl get all -o wide";
        ks = "kubectl get services -o wide";
        kap = "kubectl apply -f ";
        # Tools
        claude-monitor = "uv tool run claude-monitor";
      };

      shellAbbrs = {
        copy =
          if isDarwin
          then "pbcopy"
          else "xclip -selection clipboard";
      };

      # 2. Fish Functions (legacy shell helpers migrated to fish)
      functions =
        {
          # Kubernetes manifest viewer
          kube-manifest = {
            body = ''
              kubectl get $argv -o name | \
                fzf --preview 'kubectl get {} -o yaml' \
                    --bind "ctrl-r:reload(kubectl get $argv -o name)" \
                    --bind "ctrl-i:execute(kubectl edit {+})" \
                    --header 'Ctrl-I: live edit | Ctrl-R: reload list'
            '';
          };

          # Git log with preview
          gitlog = {
            body = "git log --oneline | fzf --preview 'git show --color=always {1}'";
          };

          # Process viewer
          pslog = {
            body = "ps axo pid,rss,comm --no-headers | fzf --preview 'ps o args {1}; ps mu {1}'";
          };

          # Package dependencies viewer
          pckg-dep = {
            body = "apt-cache search . | fzf --preview 'apt-cache depends {1}'";
          };

          # Search files by keyword
          search = {
            body = ''
              if not set -q argv[1]
                  echo "provide regex argument"
                  return 1
              end

              set -l matching_files
              if test "$argv[1]" = "-h"
                  set -l query $argv[2]
                  set matching_files (rg -l --hidden $query | fzf --exit-0 --preview="rg --color=always -n -A 20 '$query' {}")
              else
                  set -l query $argv[1]
                  set matching_files (rg -l -- $query | fzf --exit-0 --preview="rg --color=always -n -A 20 -- '$query' {}")
              end

              if test -n "$matching_files"
                  set -l search_term $argv[-1]
                  $EDITOR "$matching_files" -c "/$search_term"
              end
            '';
          };
        }
        // (lib.optionalAttrs isLinux {
          # Linux 전용 systemd 로그 뷰어
          systemdlog = {
            body = ''
              find /etc/systemd/system/ -name "*.service" | \
                fzf --preview 'cat {}' \
                    --bind "ctrl-i:execute(nvim {})" \
                    --bind "ctrl-s:execute(cat {} | copy)"
            '';
          };
        })
        // (lib.optionalAttrs isDarwin {
          # macOS 전용 launchd 로그 뷰어
          systemdlog = {
            body = ''
              launchctl list | \
                fzf --preview 'launchctl print system/{1} 2>/dev/null || launchctl print user/(id -u)/{1} 2>/dev/null || echo "Service details not available"' \
                    --bind "ctrl-i:execute(nvim /Library/LaunchDaemons/{1}.plist 2>/dev/null || nvim /System/Library/LaunchDaemons/{1}.plist 2>/dev/null || nvim ~/Library/LaunchAgents/{1}.plist 2>/dev/null || echo 'Plist file not found')" \
                    --bind "ctrl-s:execute(launchctl print system/{1} 2>/dev/null | pbcopy || launchctl print user/(id -u)/{1} 2>/dev/null | pbcopy)" \
                    --header 'Ctrl-I: edit plist | Ctrl-R: reload list | Ctrl-S: copy service info'
            '';
          };
        });

      # 3. Interactive Shell Init (환경 변수 및 초기화)
      loginShellInit = ''
        # Ensure fzf is on PATH before Home Manager's fish integration runs.
        fish_add_path --move --prepend ${pkgs.fzf}/bin
      '';

      interactiveShellInit = ''
        # 1. Bass를 이용한 POSIX 스크립트 소싱 (Nix Daemon 등)
        if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
            bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        end

        # 2. Keep the first fish launch clean while Tide is loaded separately.
        set -g fish_greeting

        # 3. Load zellij subcommand completion directly from the package.
        ${pkgs.zellij}/bin/zellij setup --generate-completion fish | source

        # 4. Key Bindings (Home/End keys)
        bind \e\[H beginning-of-line
        bind \e\[F end-of-line

        # 5. Linux 전용 Linger 설정
        ${lib.optionalString isLinux ''
          if not loginctl show-user "$USER" | grep -q "Linger=yes"
              loginctl enable-linger "$USER"
          end
        ''}

        # 6. 테마 초기화 (Tide는 activation에서 1회 설정)
      '';

      # 4. 필수 플러그인
      plugins =
        map (name: {
          inherit name;
          src = pkgs.fishPlugins.${name}.src;
        }) [
          "bass"
          "done"
          "tide"
        ];
    };
    direnv = {
      enable = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
      silent = true;
    };
    fzf = {
      enable = true;
      enableBashIntegration = true;
      defaultOptions = [
        "--info=inline"
        "--border=rounded"
        "--margin=1"
        "--padding=1"
      ];
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        LazyVim
        nvim-treesitter.withAllGrammars
      ];
    };
    git = {
      enable = true;
      settings = {
        user = {
          name = "limjihoon";
          email = "lonelynight1026@gmail.com";
        };
        credential.helper = "store";
      };
      signing.format = "openpgp";
    };
    yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "y";
      theme = {
        filetype = {
          rules = [
            {
              fg = "#7AD9E5";
              mime = "image/*";
            }
            {
              fg = "#F3D398";
              mime = "video/*";
            }
            {
              fg = "#F3D398";
              mime = "audio/*";
            }
            {
              fg = "#CD9EFC";
              mime = "application/bzip";
            }
          ];
        };
      };
    };

  };

  home.activation.tideBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${lib.getExe pkgs.fish} -lc 'set -q tide_left_prompt_items' >/dev/null 2>&1; then
      ${lib.getExe pkgs.fish} -lc 'tide configure --auto --style=Lean --prompt_colors="True color" --prompt_connection=Disconnected --prompt_spacing=Compact --show_time=No --icons="Few icons" --transient=No --lean_prompt_height="One line" --finish="Overwrite your current tide config"'
    fi
  '';
}
