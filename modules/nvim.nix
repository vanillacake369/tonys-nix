{ pkgs, lib, ... }:
{

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;
      # All configuration resides in dotfiles/lazyvim
      plugins = with pkgs.vimPlugins; [ LazyVim ];
    };
  };

}
