{pkgs, ...}: {
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
    # - The python3 provider path is emitted via nix-providers.lua below;
    #   tonys-nvim's init.lua dofile's it when present.
    #
    # An earlier attempt used xdg.configFile."nvim/init.lua".source =
    # mkForce (mkOutOfStoreSymlink "${homeDir}/.config/nvim/init.lua") to
    # let home-manager "manage" init.lua without overwriting it, but a
    # source path equal to the target path creates a two-hop self-referential
    # symlink chain (target → /nix/store/<hash> → target) that triggers
    # ELOOP at nvim startup. Dropping the override entirely (since
    # programs.neovim now writes no init.lua) avoids the cycle.
  };

  # Nix-managed provider configuration. tonys-nvim's init.lua dofile's this
  # file under a fs_stat guard so non-Nix users skip it silently.
  #
  # python3_host_prog: pin to a pkgs.python3 with pynvim so the python3
  #   provider works without depending on whatever PATH-resolved python3
  #   happens to be first (which on macOS may be Apple's framework python).
  # node_host_prog: intentionally omitted. The neovim-node-host package
  #   moved out of pkgs.nodePackages in nixpkgs 2026-03 and pinning it
  #   reliably across nixpkgs revisions is brittle. nvim falls back to
  #   PATH-based detection (`node` + npm root -g neovim), which works
  #   when `programs.neovim.withNodeJs = true` puts nodejs on PATH.
  # ruby/perl: disabled to silence :checkhealth warnings on systems
  #   without those runtimes.
  xdg.configFile."nvim/nix-providers.lua".text = ''
    vim.g.python3_host_prog = "${(pkgs.python3.withPackages (ps: [ps.pynvim])).interpreter}"
    vim.g.loaded_ruby_provider = 0
    vim.g.loaded_perl_provider = 0
  '';
}
