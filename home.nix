{ lib, pkgs, ... }: 
{
  # Enable home-manager
  programs.home-manager.enable = true;


  home = {
    # Install packages from https://search.nixos.org/packages
    packages = with pkgs; [
      # Neovim
      neovim
      spacevim
      # Zsh. Can't live without it
      zsh
      zsh-autoenv
      zsh-powerlevel10k
      # fzf for zsh shell. Helps me to find commands.
      fzf
      # kubernetes
      kubectl
      kubectx
      k9s
      stern
      kubernetes-helm
      kubectl-tree
    ];
    
    # This needs to be set to your actual username.
    username = "limjihoon";
    homeDirectory = "/home/limjihoon";

    # Don't ever change this after the first build.
    # It tells home-manager what the original state schema
    # was, so it knows how to go to the next state.  It
    # should NOT update when you update your system!
    # stateVersion = "25.05";
    stateVersion = "23.11";

    # Aliases for my shell
    shellAliases = {
      kctx="kubectx";
      kns="kubens";
      k="kubectl";
    };

  };


  programs = {

    # Setup for zsh
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

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

