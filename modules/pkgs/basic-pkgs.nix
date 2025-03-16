{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Neovim
    neovim
    spacevim
    # Zsh
    zsh
    oh-my-zsh
    zsh-autoenv
    zsh-powerlevel10k
    zsh-syntax-highlighting
    zsh-fzf-tab
    # zsh-autosuggestions
    # fzf for command search
    fzf
  ];
}

