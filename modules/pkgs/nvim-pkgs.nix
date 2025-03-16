{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Neovim
    neovim
    spacevim
  ];
  programs = {
    
    # Setup for neovim
    neovim = {
      enable = true;
    };
  };
}

