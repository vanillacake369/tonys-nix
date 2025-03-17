{ pkgs, ... }: {
  home.packages = with pkgs; [
    # zsh
    # oh-my-zsh
    zsh-autoenv
    zsh-powerlevel10k
    # zsh-syntax-highlighting
    # zsh-fzf-tab
    # zsh-autosuggestions
  ];
  programs = {
    
    # Setup for zsh
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
          ka = "kubectl get all -o wide";
          ks = "kubectl get services -o wide";
          kap = "kubectl apply -f ";
      };
      
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "kubectl"
          "kube-ps1"
        ];
        theme = "powerlevel10k/powerlevel10k";
      };

      # Source zsh-autoenv manually
      initExtra = ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-''$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi


        # Apply zsh-autoenv
        source ${pkgs.zsh-autoenv}/share/zsh-autoenv/autoenv.zsh

        # Apply zsh-powerlevel10k
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

        # Enable home & end key
        case $TERM in (xterm*)
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        esac

        # Avoid for Home Manager to manage your shell configuration
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
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

