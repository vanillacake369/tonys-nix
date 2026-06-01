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
    # NOTE: initLua intentionally absent.
    # - With empty initLua/extraLuaConfig/extraConfig, programs.neovim does
    #   not write ~/.config/nvim/init.lua at all (mkIf guard on luaConfigStr).
    # - tonys-nvim (https://github.com/vanillacake369/tonys-nvim) is cloned
    #   to ~/.config/nvim and owns init.lua as a regular tracked file.
    # - Provider host paths (vim.g.python3_host_prog, vim.g.node_host_prog)
    #   are emitted to a separate nix-managed file (nix-providers.lua below)
    #   that tonys-nvim's init.lua dofile's at startup.
    #
    # The earlier xdg.configFile."nvim/init.lua".source = mkForce
    # (mkOutOfStoreSymlink "${homeDir}/.config/nvim/init.lua") attempt was
    # reverted because mkOutOfStoreSymlink with a source path equal to the
    # target path creates a two-hop self-referential symlink chain
    # (~/.config/nvim/init.lua -> /nix/store/<hash>-init.lua ->
    # ~/.config/nvim/init.lua) that triggers ELOOP at nvim startup.
  };

  # Nix-managed provider host paths for tonys-nvim. This file is dofile'd by
  # tonys-nvim's init.lua when present (non-Nix users simply skip the load).
  # Splitting providers out of init.lua keeps init.lua mutable and standalone
  # while still injecting Nix-pinned paths.
  xdg.configFile."nvim/nix-providers.lua".text = ''
    vim.g.node_host_prog = "${pkgs.nodePackages.neovim}/bin/neovim-node-host"
    vim.g.python3_host_prog = "${(pkgs.python3.withPackages (ps: [ps.pynvim])).interpreter}"
    vim.g.loaded_ruby_provider = 0
    vim.g.loaded_perl_provider = 0
  '';
}
