{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Neovim
    neovim = {
	enable = true;
	defaultEditor = true;
	viAlias = true;
	vimAlias = true;
	vimdiffAlias = true;
    };
    spacevim
  ];
}

