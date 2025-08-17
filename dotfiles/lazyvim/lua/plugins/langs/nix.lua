-- Nix language support configuration
-- Provides LSP support with nixd and alejandra formatting

return {
  -- LSP Configuration for Nix
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nil_ls = {
          settings = {
            ['nil'] = {
              formatting = {
                command = { "alejandra" },
              },
            },
          },
        },
      },
    },
  },

  -- Configure Conform to use alejandra for .nix files
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.nix = { "alejandra" }
      return opts
    end,
  },
}
