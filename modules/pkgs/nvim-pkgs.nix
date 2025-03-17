{ pkgs, ... }: {
  home.packages = with pkgs; [
    spacevim
  ];

  programs = {
    neovim = {
	enable = true;
	defaultEditor = true;
	viAlias = true;
	vimAlias = true;
	vimdiffAlias = true;
    };
  };
}

