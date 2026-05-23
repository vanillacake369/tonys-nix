_: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = false;
    withNodeJs = true;
    withPython3 = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    # programs.neovim owns init.lua to inject *_host_prog. Delegate to a
    # mutable bootstrap (vanillacake369/tonys-nvim) so LazyVim spec lives
    # outside the nix store and can iterate without rebuilds.
    initLua = ''
      local user_init = vim.fn.stdpath('config') .. '/init.user.lua'
      if (vim.uv or vim.loop).fs_stat(user_init) then
        dofile(user_init)
      else
        vim.notify('init.user.lua not found at ' .. user_init, vim.log.levels.WARN)
      end
    '';
  };
}
