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
      k = "kubectl";
      m = "minikube";
      kctx = "kubectx";
      ka = "kubectl get all -o wide";
      ks = "kubectl get services -o wide";
      kap = "kubectl apply -f ";
      zj = "zellij";
      hm = "home-manager";
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
      if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      end

      fish_add_path --move --prepend $HOME/.cargo/bin

      set -g fish_greeting
      ${pkgs.zellij}/bin/zellij setup --generate-completion fish | source

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
}
