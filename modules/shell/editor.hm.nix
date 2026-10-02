{
  lib,
  pkgs,
  ...
}: let
  luaRocksEnv = pkgs.lua5_1.withPackages (luaPackages: [
    luaPackages.luarocks
    luaPackages.luarocks-build-treesitter-parser
  ]);
  # Lazy.nvim은 플러그인 코드를 관리하고, LuaRocks는 rock 의존성만 설치한다.
  # rest.nvim의 rockspec은 Lua 5.1 환경과 tree-sitter-http 빌드 백엔드를
  # 요구하므로, Neovim 전용 도구 체인을 Nix로 고정해 시스템 Lua와 분리한다.
  # 주의: Lazy의 hererocks를 끄고 이 luarocks 래퍼가 PATH에서 선택되어야 한다.
  # 각 플러그인의 쓰기 가능한 rock 설치 경로는 Lazy가 계속 관리하며,
  # 아래 Nix tree는 빌드 백엔드 같은 실행 도구를 제공하는 용도다.
  # rocks.enabled = false 로 끄면 rest.nvim의 LuaRocks 의존성을 해결할 수 없다.
  luaRocksConfig = pkgs.writeText "neovim-luarocks-config.lua" ''
    rocks_trees = {{
      name = "nix-runtime";
      root = "${luaRocksEnv}";
    }}
  '';
  # 별도 래퍼로 설정 파일을 지정해 일반 터미널의 LuaRocks 설정과 섞이지 않게 한다.
  luaRocks = pkgs.writeShellScriptBin "luarocks" ''
    export LUAROCKS_CONFIG=${luaRocksConfig}
    exec ${luaRocksEnv}/bin/luarocks "$@"
  '';
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withNodeJs = true;
    withPython3 = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = [
      luaRocks
      luaRocksEnv
    ];
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
