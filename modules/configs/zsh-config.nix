{ pkgs, ... }: {

  programs = {
    
    # Setup for zsh
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
          ll = "ls -l";
          update = "sudo nixos-rebuild switch";
          kctx = "kubectx";
          kns = "kubens";
          k = "kubectl";
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
      # Apply zsh-autoenv
      source ${pkgs.zsh-autoenv}/share/zsh-autoenv/autoenv.zsh
      source ~/.zshrc
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

