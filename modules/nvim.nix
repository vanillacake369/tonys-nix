{ pkgs, lib, ... }: {

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      plugins = with pkgs.vimPlugins; [
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        plenary-nvim
        LazyVim
        gruvbox-material
        mini-nvim
        vim-just
        yazi-nvim
        vim-visual-multi
        packer-nvim
	lazygit-nvim
      ];
    };
  };

}
