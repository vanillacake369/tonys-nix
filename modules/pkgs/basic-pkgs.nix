{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Neovim
    neovim
    spacevim
    # Zsh
    zsh
    zsh-autoenv
    zsh-powerlevel10k
    # fzf for command search
    fzf
  ];
}

