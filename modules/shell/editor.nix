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
  };

  # Disable home-manager's xdg.configFile."nvim/init.lua" entry so the
  # standalone tonys-nvim clone at ~/.config/nvim owns init.lua directly.
  #
  # Why this is needed (verified against live home-manager source):
  #
  #   modules/programs/neovim.nix:553
  #     "nvim/init.lua" = mkIf (cfg.initLua != "") { text = cfg.initLua; };
  #   modules/programs/neovim.nix:476
  #     wrapperHasUserConfig =
  #       wrappedNeovim'.luaRcContent != wrappedNeovim'.providerLuaRc;
  #   modules/programs/neovim.nix:527-530
  #     mkIf wrapperHasUserConfig (mkOrder 200 wrappedNeovim'.luaRcContent)
  #
  # `wrapperHasUserConfig` is true whenever the wrapper's lua rc differs from
  # just the provider preamble. nixpkgs' neovim wrapper.nix builds
  # `rcContent` (= wrapper luaRcContent) from:
  #   luaPathLuaRc (only if luaDependencies != [])
  #   + providerLuaRc
  #   + optional user luaRcContent
  #
  # nvim-treesitter contributes lua deps via vimPackageInfo.luaDependencies,
  # so luaPathLuaRc is non-empty → wrapperHasUserConfig is true →
  # programs.neovim.initLua receives wrappedNeovim'.luaRcContent → not empty
  # → mkIf at neovim.nix:553 fires → init.lua is materialized in nix-store.
  #
  # The previous workaround (drop initLua / set mkOutOfStoreSymlink / disable
  # withNodeJs/withPython3) does not help because the luaPathLuaRc path is
  # plugin-driven, not provider-driven.
  #
  # Setting `enable = false` on this specific xdg.configFile entry tells
  # home-manager to skip the activation step for ~/.config/nvim/init.lua,
  # leaving the path to whatever tonys-nvim's clone provides. withNodeJs /
  # withPython3 stay true so the wrapper's PATH still gets nodejs +
  # pkgs.python3.withPackages [ps.pynvim], which nvim's provider
  # auto-detection picks up at runtime.
  xdg.configFile."nvim/init.lua".enable = lib.mkForce false;
}
