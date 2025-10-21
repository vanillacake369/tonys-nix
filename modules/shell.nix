# Shell environment configuration
# Organized by: ZSH, FZF, CLI tools, and platform-specific packages
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
  # CLI Tools and Packages
  # =============================================================================
  home.packages = with pkgs;
    [
      # Core utilities
      zsh-autoenv
      zsh-powerlevel10k
      bat
      jq
      ripgrep
      tree
      curl
      htop
      btop

      # Git tools
      git
      lazygit

      # Container tools
      lazydocker

      # Network tools
      autossh
      lazyssh
      inetutils
      netcat

      # Monitoring and debugging
      lsof
      gdb
      smartmontools

      # Terminal tools
      zellij
      neofetch
      expect

      # Cloud tools
      awscli
      ssm-session-manager-plugin

      # Recording
      asciinema
      asciinema-agg

      # Database
      redli

      # Infrastructure tools
      k6
      kubectl
      kubectx
      k9s
      stern
      kubernetes-helm
      kubectl-tree
      ngrok
      terraform
    ]
    ++ lib.optionals isLinux [
      # Linux-specific tools
      xclip
      openssh
      psmisc
      strace
      multipass
    ]
    ++ lib.optionals (isLinux && !isWsl) [
      # Native Linux only (not WSL)
      google-authenticator
      wayland-utils
    ]
    ++ lib.optionals isDarwin [
      # macOS-specific tools
      dive
      minikube
      podman
      podman-compose
      podman-desktop
      nixos-24_11.vagrant
      qemu
    ];

  # =============================================================================
  # ZSH Configuration
  # =============================================================================
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Shell aliases
    shellAliases =
      {
        # Basic utilities
        ll = "ls -l";
        cat = "bat --style=plain --paging=never";
        grep = "rg";
        clear = "clear -x";

        # Kubernetes shortcuts
        k = "kubectl";
        m = "minikube";
        kctx = "kubectx";
        kns = "kubens";
        ka = "kubectl get all -o wide";
        ks = "kubectl get services -o wide";
        kap = "kubectl apply -f ";

        # Tools
        claude-monitor = "uv tool run claude-monitor";

        # Clipboard (platform-specific)
        copy =
          if pkgs.stdenv.isDarwin
          then "pbcopy"
          else "xclip -selection clipboard";
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        hidden-bar = "open ~/.nix-profile/Applications/\"Hidden Bar.app\"";
      };

    # Powerlevel10k theme
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    # Oh-My-Zsh plugins
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "kubectl"
        "kube-ps1"
      ];
    };

    # ZSH initialization script
    initContent = ''
      # Powerlevel10k instant prompt
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # Apply zsh-autoenv
      source ${pkgs.zsh-autoenv}/share/zsh-autoenv/autoenv.zsh

      # Apply powerlevel10k theme
      source ~/.p10k.zsh

      # Enable Home/End keys
      case $TERM in (xterm*)
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      esac

      # Load home-manager session variables
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

      # Enable systemd user session lingering (Linux only)
      ${lib.optionalString pkgs.stdenv.isLinux ''
        if ! loginctl show-user "$USER" | grep -q "Linger=yes"; then
          loginctl enable-linger "$USER"
        fi
      ''}

      # Smart container aliases - prefer podman, fallback to docker
      if command -v podman >/dev/null 2>&1; then
        alias docker='podman'
      fi

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
  };

  # =============================================================================
  # FZF Configuration
  # =============================================================================
  programs.fzf = {
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

  # =============================================================================
  # Other CLI Programs
  # =============================================================================
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [LazyVim];
  };

  programs.git = {
    enable = true;
    userName = "limjihoon";
    userEmail = "lonelynight1026@gmail.com";
  };

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
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

  # =============================================================================
  # Platform-Specific Configurations
  # =============================================================================
  # Multipass Daemon Service (Linux only)
  systemd.user.services.multipassd = lib.mkIf isLinux {
    Unit = {
      Description = "Multipass VM manager daemon";
      After = ["network.target"];
    };

    Service = {
      Type = "simple";
      RemainAfterExit = true;
      TimeoutStartSec = 600;
      ExecStart = "${pkgs.multipass}/bin/multipassd";
      Restart = "on-failure";
      RestartSec = 5;
      StandardOutput = "journal";
      StandardError = "journal";
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  # Podman Desktop configuration (macOS and native Linux)
  home.file = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    ".local/share/containers/podman-desktop/configuration/settings.json".text = builtins.toJSON {
      "podman.binary.path" = "${config.home.homeDirectory}/.nix-profile/bin/podman";
    };
  };

  # Vagrant with QEMU configuration (macOS and native Linux)
  home.sessionVariables = lib.optionalAttrs (isDarwin || (isLinux && !isWsl)) {
    VAGRANT_QEMU_DIR = "${pkgs.qemu}/share/qemu";
    VAGRANT_DEFAULT_PROVIDER = "qemu";
  };
}
