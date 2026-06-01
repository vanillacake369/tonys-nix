{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withNodeJs = true;
    withPython3 = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    # nvim-treesitter with all grammar derivations bundled into the wrapper's
    # rtp. Without this, the lua plugin loads but `vim.treesitter` can't find
    # any parser → treesitter-dependent tools (neotest, render-markdown,
    # incremental_selection, etc.) fail silently while vim falls back to
    # regex-based syntax highlighting. `withAllGrammars` exposes every parser
    # via passthru.dependencies, which home-manager's neovim wrapper symlinks
    # into the rtp.
    plugins = [pkgs.vimPlugins.nvim-treesitter.withAllGrammars];
    # NOTE: initLua intentionally absent. Previously this shim dofile'd
    # init.user.lua to delegate to vanillacake369/tonys-nvim, but managing
    # init.lua via programs.neovim writes it as a nix-store symlink that
    # collides with the standalone tonys-nvim clone at ~/.config/nvim
    # (permanent `T` typechange in git). The xdg.configFile override below
    # routes init.lua to the mutable repo while keeping every other wrapper
    # benefit (defaultEditor UTI, withNodeJs/Python3 provider injection,
    # viAlias/vimAlias binary wrappers, withAllGrammars treesitter bundle).
  };

  # tonys-nvim (https://github.com/vanillacake369/tonys-nvim) is cloned to
  # ~/.config/nvim and owns init.lua as a regular tracked file. mkForce
  # overrides programs.neovim's generated init.lua entry; mkOutOfStoreSymlink
  # records the path as managed-but-mutable so home-manager activation
  # leaves the file in place instead of writing a nix-store symlink.
  xdg.configFile."nvim/init.lua".source =
    lib.mkForce
    (config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/nvim/init.lua");
}
