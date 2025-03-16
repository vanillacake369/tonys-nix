{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Neovim
    neovim
    spacevim
  ];
}

