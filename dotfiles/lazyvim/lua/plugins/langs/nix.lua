return {
  -- Mason LSP configuration for automatic server management
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "nixd", -- Ensure nixd LSP server is installed via Mason
      })
    end,
  },

  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import <nixpkgs> { }",
              },
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
