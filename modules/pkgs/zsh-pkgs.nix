{ pkgs, ... }: {
  home.packages = with pkgs; [
    zsh-autoenv
    zsh-powerlevel10k
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
          m = "minikube";
          ka = "kubectl get all -o wide";
          ks = "kubectl get services -o wide";
          kap = "kubectl apply -f ";
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
          "powerlevel10k"
        ];
        # theme = "powerlevel10k/powerlevel10k";
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
        # source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
	source ~/.p10k.zsh

        # Enable home & end key
        case $TERM in (xterm*)
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        esac

        # Avoid for Home Manager to manage your shell configuration
        . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

        # Enable session managed by systemd
        if ! loginctl show-user "$USER" | grep -q "Linger=yes"; then
          loginctl enable-linger "$USER"
        fi

        # Enable DOCKER_HOST
        export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock
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

