return {
  -- Install alejandra automatically
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "alejandra" },
    },
  },

  -- Configure Conform to use alejandra
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = vim.tbl_deep_extend("force", opts.formatters_by_ft or {}, {
        nix = { "alejandra" },
      })
    end,
  },
}
