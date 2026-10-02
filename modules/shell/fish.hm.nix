{
  pkgs,
  lib,
  isDarwin,
  isLinux,
  ...
}: {
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -l";
      cat = "bat --style=plain --paging=never";
      grep = "rg";
      clear = "clear -x";
      pdm = "podman";
      dck = "docker";
      k = "kubectl";
      m = "minikube";
      kctx = "kubectx";
      ka = "kubectl get all -o wide";
      ks = "kubectl get services -o wide";
      kap = "kubectl apply -f ";
      zj = "zellij";
      zr = "zellij-nav repo";
      hm = "home-manager";
      tscl = "tailscale";
      mtps = "multipass";
      codex = "agent-secret-env codex";
      cdx = "agent-secret-env codex -s danger-full-access -a never";
      gmni = "agent-secret-env agy --dangerously-skip-permissions";
    };

    shellAbbrs = {
      copy =
        if isDarwin
        then "pbcopy"
        else "xclip -selection clipboard";
    };

    functions =
      {
        kube-manifest = {
          body = ''
            kubectl get $argv -o name | \
              fzf --preview 'kubectl get {} -o yaml' \
                  --bind "ctrl-r:reload(kubectl get $argv -o name)" \
                  --bind "ctrl-i:execute(kubectl edit {+})" \
                  --header 'Ctrl-I: live edit | Ctrl-R: reload list'
          '';
        };
        gitlog = {
          body = "git log --oneline | fzf --preview 'git show --color=always {1}'";
        };
        pslog = {
          body = "ps axo pid,rss,comm --no-headers | fzf --preview 'ps o args {1}; ps mu {1}'";
        };
        pckg-dep = {
          body = "apt-cache search . | fzf --preview 'apt-cache depends {1}'";
        };
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
        dhost = {
          body = ''
            set -l cmd $argv[1]
            set -l machine podman-machine-default

            switch "$cmd"
                case podman p
                    if not type -q podman
                        echo "podman not found"
                        return 1
                    end

                    set -l podman_socket (podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' $machine 2>/dev/null)
                    if test -z "$podman_socket"; or not test -S "$podman_socket"
                        echo "podman socket not available: $machine"
                        return 1
                    end

                    set -Ux DOCKER_HOST "unix://$podman_socket"
                    echo "DOCKER_HOST=$DOCKER_HOST"

                case docker d
                    set -e DOCKER_HOST
                    set -eU DOCKER_HOST
                    echo "DOCKER_HOST unset; docker default will be used"

                case status s ""
                    if set -q DOCKER_HOST
                        echo "DOCKER_HOST=$DOCKER_HOST"
                    else
                        echo "DOCKER_HOST unset; docker default will be used"
                    end

                    if type -q podman
                        set -l podman_socket (podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' $machine 2>/dev/null)
                        if test -n "$podman_socket"; and test -S "$podman_socket"
                            echo "podman socket available: $podman_socket"
                        else
                            echo "podman socket unavailable: $machine"
                        end
                    else
                        echo "podman not found"
                    end

                case '*'
                    echo "usage: dhost podman|docker|status"
                    return 2
            end
          '';
        };
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

    loginShellInit = ''
      fish_add_path --move --prepend ${pkgs.fzf}/bin
    '';

    interactiveShellInit = ''
      if not set -q NIX_PROFILES; and test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      end

      fish_add_path --move --prepend $HOME/.cargo/bin

      ${lib.optionalString isDarwin ''
        if type -q brew
            set -l brew_prefix (brew --prefix)
            set -l brew_completion_dirs \
                $brew_prefix/share/fish/completions \
                $brew_prefix/share/fish/vendor_completions.d

            for formula in podman docker
                set -l formula_prefix (brew --prefix $formula 2>/dev/null)
                if test -n "$formula_prefix"
                    set -a brew_completion_dirs $formula_prefix/share/fish/vendor_completions.d
                end
            end

            for completion_dir in $brew_completion_dirs
                if test -d $completion_dir; and not contains -- $completion_dir $fish_complete_path
                    set -a fish_complete_path $completion_dir
                end
            end
        end
      ''}

      set -g fish_greeting

      bind \e\[H beginning-of-line
      bind \e\[F end-of-line

      ${lib.optionalString isLinux ''
        if not loginctl show-user "$USER" | grep -q "Linger=yes"
            loginctl enable-linger "$USER"
        end
      ''}

      set -g fish_color_command green
      set -g fish_color_error red --bold
      set -g fish_color_param blue
      set -g fish_color_quote yellow
      set -g fish_color_redirection cyan
      set -g fish_color_end white
    '';

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

  home.activation.tideBootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if ! ${lib.getExe pkgs.fish} -lc 'set -q tide_left_prompt_items' >/dev/null 2>&1; then
      ${lib.getExe pkgs.fish} -lc 'tide configure --auto --style=Lean --prompt_colors="True color" --prompt_connection=Disconnected --prompt_spacing=Compact --show_time=No --icons="Few icons" --transient=No --lean_prompt_height="One line" --finish="Overwrite your current tide config"'
    fi
  '';
  home.file.".config/fish/completions/zellij.fish".source = pkgs.runCommand "zellij-fish-completion" {} ''
    ${pkgs.zellij}/bin/zellij setup --generate-completion fish > "$out"
  '';

  # Just's native dynamic completion discovers the nearest justfile. The
  # additional candidates below are guarded by structural repository markers,
  # so tonys-nix vocabulary never leaks into unrelated directories.
  home.file.".config/fish/completions/just.fish".source = ../../completions/just-tonys-nix.fish;
}
