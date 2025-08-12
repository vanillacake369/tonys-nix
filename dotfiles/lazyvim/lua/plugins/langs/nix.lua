-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins
return {

  -- LSP
  {
    "neovim/nvim-lspconfig",
    ft = { "nix" },
    opts = {
      servers = {
        nixd = {
          cmd = { "nixd" },
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
              },
              formatting = {
                command = { "alejandra" },
              },
              options = {
                nixos = {
                  expr = "let flake = builtins.getFlake(toString ./.); in flake.nixosConfigurations.limjihoon.options",
                },
                home_manager = {
                  expr = "let flake = builtins.getFlake(toString ./.); in flake.homeConfigurations.limjihoon.options",
                },
              },
            },
          },
        },
      },
    },
  },

  -- Conform.nvim formatter for Nix
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.nix = { "alejandra" }
      
      opts.formatters = opts.formatters or {}
      opts.formatters.alejandra = {
        command = "alejandra",
        args = { "--quiet" },
        stdin = true,
      }
    end,
  },

}
