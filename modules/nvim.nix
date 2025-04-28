{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    vimPlugins.vim-visual-multi
  ];

  # install spacevim if not installed
  home.activation.installSpaceVim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.SpaceVim" ]; then
      echo "Installing SpaceVim..."
      export PATH=${pkgs.git}/bin:$PATH
      ${pkgs.curl}/bin/curl -sLf https://spacevim.org/install.sh | ${pkgs.bash}/bin/bash
    else
      echo "SpaceVim already installed, skipping..."
    fi
  '';

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
        gruvbox-material
        mini-nvim
        vim-just
        yazi-nvim
        # vim-visual-multi
      ];
    };
  };

}

