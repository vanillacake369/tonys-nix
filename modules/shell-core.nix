# Core shell environment configuration
# ZSH, FZF, and basic shell setup
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
    initExtra = ''
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
  # Core Shell Packages
  # =============================================================================
  home.packages = with pkgs; [
    # ZSH theme and plugins
    zsh-autoenv
    zsh-powerlevel10k
  ];

  # =============================================================================
  # Other Essential CLI Programs
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
}
