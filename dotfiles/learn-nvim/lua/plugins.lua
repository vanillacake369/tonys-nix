local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
  print("Installing packer close and reopen Neovim...")
end

-- Install plugins here
return require('packer').startup(function(use)
 use 'wbthomason/packer.nvim'
 use 'williamboman/mason.nvim'   
 use 'williamboman/mason-lspconfig.nvim'
 use 'neovim/nvim-lspconfig'
end)
